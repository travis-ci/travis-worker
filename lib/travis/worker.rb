require 'simple_states'
require 'multi_json'
require 'thread'
require 'core_ext/hash/compact'
require 'travis/build'
require 'travis/support'
require 'hard_timeout'

module Travis
  autoload :Serialization,      'travis/serialization'

  class Worker
    autoload :Application,      'travis/worker/application'
    autoload :Config,           'travis/worker/config'
    autoload :Factory,          'travis/worker/factory'
    autoload :Pool,             'travis/worker/pool'
    autoload :Shell,            'travis/worker/shell'
    autoload :VirtualMachine,   'travis/worker/virtual_machine'

    module Reporters
      autoload :LogStreamer,    'travis/worker/reporters/log_streamer'
      autoload :StateReporter,  'travis/worker/reporters/state_reporter'
    end

    class BuildStallTimeoutError < StandardError; end

    class << self
      def config
        @config ||= Config.new
      end
    end

    include SimpleStates, Logging

    log_header { "#{name}:worker" }

    def self.create(name, config, broker_connection)
      Factory.new(name, config, broker_connection).worker
    end

    states :created, :starting, :ready, :working, :stopping, :stopped, :errored

    attr_accessor :state, :state_reporter
    attr_reader :name, :vm, :broker_connection, :queues, :queue_names, :consumers, :config, :payload, :last_error

    def initialize(name, vm, broker_connection, queue_names, config)
      raise ArgumentError, "worker name cannot be nil!" if name.nil?
      raise ArgumentError, "VM cannot be nil!" if vm.nil?
      raise ArgumentError, "broker connection cannot be nil!" if broker_connection.nil?
      raise ArgumentError, "config cannot be nil!" if config.nil?

      @name              = name
      @vm                = vm
      @queue_names       = queue_names
      @broker_connection = broker_connection
      @config            = config

      initialize_state_reporter
    end

    def start
      set :starting
      vm.prepare
      set :ready

      open_channels
      declare_queues
      subscribe
    end
    log :start

    def stop(options = {})
      set :stopping
      shutdown_consumers
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


    def shutdown
      shutdown_consumers
      close_channels
    end


    protected

    def open_channels
      # error handling happens on the per-channel basis, so using
      # one channel for one type of operation is a highly recommended practice. MK.
      open_builds_consumer_channels
      open_reporting_channel
    end

    def close_channels
      # channels may be nil in some tests that mock out #start and #stop. MK.
      @build_consumer_channels.each do |_, ch|
        ch.close if ch.open?
      end if @build_consumer_channels
      @reporting_channel.close      if @reporting_channel && @reporting_channel.open?
    end

    def open_builds_consumer_channels
      # technically there is no need to use one channel per consumer but with RabbitMQ version on
      # Heroku (2.5) this is the only way to go :/ 2.6 and 2.7 on my local network work just fine.
      # But hey, Heroku gods, we must obey to. For now. MK.
      @build_consumer_channels = @queue_names.reduce({}) do |acc, q|
        acc[q]          = @broker_connection.create_channel
        acc[q].prefetch = 1
        acc
      end
    end

    def open_reporting_channel
      @reporting_channel = @broker_connection.create_channel
    end

    def declare_queues
      # the list of queues is passed on from Travis::Worker::Factory. MK.
      @queues = @queue_names.map do |name|
        # see comments in open_builds_consumer_channels about why we are using
        # one channel per queue. MK.
        @build_consumer_channels[name].queue(name, :durable => true)
      end

      # these are declared here mostly to aid development purposes. Hub is just as involved
      # in build log streaming so it may seem more logical to move these declarations to Hub. We may
      # do it in the future. MK.
      @reporting_channel.queue(Travis::Worker.config.logging_channel, :durable => true)
    end

    def subscribe
      @consumers = @queues.map { |q| q.subscribe(:ack => true, :blocking => false, &method(:process)) }
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

    def initialize_state_reporter
      # reports worker states, for example, whether worker is
      # ready, occupied or has issues. Build log streaming is done
      # using a separate class that is instantiated on the per-request basis. MK.
      @state_reporter    = Reporters::StateReporter.new(name, @broker_connection.create_channel)
    end

    def set(state)
      self.state = state
      @state_reporter.notify('worker:status', :workers => [report])
    end

    def process(message, payload)
      work(message, payload)
    rescue Errno::ECONNREFUSED, Exception => error
      # puts error.message, error.backtrace
      error_build(error, message)
    end

    def work(message, payload)
      prepare(payload)

      info "starting job slug:#{self.payload['repository']['slug']} id:#{self.payload['job']['id']}"
      info "this is a requeued message" if message.redelivered?

      build_log_streamer = log_streamer(message, payload)

      build = Build.create(vm, vm.shell, build_log_streamer, self.payload, config)
      hard_timeout(build)

      finish(message)
    rescue BuildStallTimeoutError => e
      error "the job (slug:#{self.payload['repository']['slug']} id:#{self.payload['job']['id']}) stalled and was requeued"
      finish(message, :requeue => true)
    rescue VirtualMachine::VmFatalError => e
      error "the job (slug:#{self.payload['repository']['slug']} id:#{self.payload['job']['id']}) was requeued as the vm had a fatal error"
      finish(message, :requeue => true)
    ensure
      build_log_streamer.close if build_log_streamer
    end
    log :work, :as => :debug

    def prepare(payload)
      @last_error = nil
      @payload = decode(payload)
      Travis.uuid = @payload.delete(:uuid)
      set :working
    end
    log :prepare, :as => :debug

    def finish(message, opts = {})
      unless opts[:requeue]
        message.ack
      else
        message.reject(:requeue => true)
      end
      @payload = nil
      if working?
        set :ready
      elsif stopping?
        set :stopped
      end
    end
    log :finish, :params => false

    def error_build(error, message)
      @last_error = [error.message, error.backtrace].flatten.join("\n")
      log_exception(error)
      message.reject(:requeue => true)
      stop
      set :errored
    end
    log :error, :as => :debug

    def log_streamer(message, payload)
      Reporters::LogStreamer.new(name, @broker_connection.create_channel, @broker_connection.create_channel)
    end

    def host
      Travis::Worker.config.host
    end

    def decode(payload)
      Hashr.new(MultiJson.decode(payload))
    end

    def hard_timeout(build)
      HardTimeout.timeout(config.timeouts.hard_limit) do
        Thread.current[:log_header] = name
        build.run
      end
    rescue Timeout::Error => e
      build.vm_stall
      raise BuildStallTimeoutError, 'The VM stalled and the hardtimeout fired'
    end
  end
end
