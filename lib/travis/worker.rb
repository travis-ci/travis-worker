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
    attr_reader :name, :vm, :queues, :reporter, :config, :payload, :last_error

    def initialize(name, vm, queues, reporter, config)
      @name     = name
      @vm       = vm
      @queues   = queues
      @reporter = reporter
      @config   = config
    end

    def start
      set :starting
      vm.prepare
      set :ready
      subscribe
    end
    log :start

    def stop(options = {})
      set :stopping
      unsubscribe
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

    protected

      def subscribe
        queues.each { |queue| queue.subscribe(:ack => true, :blocking => false, &method(:process)) }
      end

      def unsubscribe
        queues.each { |queue| queue.unsubscribe }
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
