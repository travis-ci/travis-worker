require 'simple_states'
require 'multi_json'
require 'thread'
require 'core_ext/hash/compact'
require 'travis/build'
require 'travis/support'

module Travis
  class Worker
    autoload :Application,    'travis/worker/application'
    autoload :Config,         'travis/worker/config'
    autoload :Factory,        'travis/worker/factory'
    autoload :Pool,           'travis/worker/pool'
    autoload :Reporter,       'travis/worker/reporter'
    autoload :Shell,          'travis/worker/shell'
    autoload :VirtualMachine, 'travis/worker/virtual_machine'

    class << self
      def config
        @config ||= Config.new
      end
    end

    include SimpleStates, Logging

    log_header { "#{name}:worker" }

    def self.create(name, config)
      Factory.new(name, config).worker
    end

    states :created, :starting, :ready, :working, :stopping, :stopped, :errored

    attr_accessor :state
    attr_reader :name, :vm, :queues, :queue_names, :reporter, :config, :payload, :last_error

    def initialize(name, vm, queue_names, reporter, config)
      @name        = name
      @vm          = vm
      @queue_names = queue_names
      @reporter    = reporter
      @config      = config
    end

    def start
      set :starting
      vm.prepare
      set :ready

      connect
      open_channels
      declare_queues
      subscribe
    end
    log :start

    def stop(options = {})
      set :stopping
      disconnect
      kill if options[:force]
      set :stopped unless working?
    end
    log :stop

    def kill
      vm.shell.terminate("Worker #{name} was stopped forcefully.")
    end

    def report
      { :name => name, :host => host, :state => state, :last_error => last_error, :payload => payload }
    end


    def disconnect
      if @connection
        shutdown_consumers
        close_channels

        @connection.close if @connection.open?
        @connection = nil
      end
    end


    protected

    def connect
      @connection = HotBunnies.connect(config.fetch(:amqp, {}))
    end

    def open_channels
      # error handling happens on the per-channel basis, so using
      # one channel for one type of operation is a highly recommended practice. MK.
      open_builds_consumer_channel
      open_reporting_channel
    end

    def close_channels
      @build_consumer_channel.close if @build_consumer_channel.open?
      @reporting_channel.close      if @reporting_channel.open?
    end

    def open_builds_consumer_channel
      @build_consumer_channel = @config[:build_consumer_channel] = @connection.create_channel
      @build_consumer_channel.prefetch = 1
    end

    def open_reporting_channel
      @reporting_channel      = @config[:reporting_channel]      = @connection.create_channel
    end

    def declare_queues
      # the list of queues is passed on from Travis::Worker::Factory. MK.
      @queues = @queue_names.map { |name| @build_consumer_channel.queue(name, :durable => true) }
    end

    def subscribe
      @consumers = @queues.map { |queue| queue.subscribe(:ack => true, :blocking => false, &method(:process)) }
    end

    def shutdown_consumers
      # due to some aspects of how RabbitMQ Java client works and HotBunnies consumer
      # implementation that uses thread pools (JDK executor services), we need to shut down
      # consumers manually to guarantee that after disconnect we leave no active non-daemon
      # threads (that are pretty much harmless but JVM won't exit as long as they are running). MK.
      @consumers.each { |c| c.shutdown! } if @consumers
    end

    def unsubscribe
      @consumers.each { |c| c.cancel }
    end

    def set(state)
      self.state = state
      reporter.notify('worker:status', [report])
    end

    def process(message, payload)
      Thread.current[:log_header] = name
      work(message, payload)
    rescue Errno::ECONNREFUSED, Exception => error
      # puts error.message, error.backtrace
      error(error, message)
    end

    def work(message, payload)
      prepare(payload)
      Build.create(vm, vm.shell, reporter, self.payload, config).run
      finish(message)
    end
    log :work, :as => :debug

    def prepare(payload)
      @last_error = nil
      @payload = decode(payload)
      set :working
    end
    log :prepare

    def finish(message)
      message.ack
      @payload = nil
      if working?
        set :ready
      elsif stopping?
        set :stopped
      end
    end
    log :finish, :params => false

    def error(error, message)
      @last_error = [error.message, error.backtrace].flatten.join("\n")
      log_exception(error)
      message.ack(:requeue => true)
      stop
      set :errored
    end
    log :error

    def host
      Travis::Worker.config.host
    end

    def decode(payload)
      Hashr.new(MultiJson.decode(payload))
    end
  end
end
