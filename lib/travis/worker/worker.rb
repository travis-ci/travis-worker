require 'travis/build'
require 'simple_states'
require 'multi_json'
require 'thread'

module Travis
  module Worker
    # Represents a single Worker which is bound to a single VM instance.
    class Worker
      autoload :Factory, 'travis/worker/worker/factory'
      autoload :Heart,   'travis/worker/worker/heart'

      class WorkerError < StandardError; end

      include SimpleStates
      extend Util::Logging

      def self.create(name, config)
        Factory.new(name, config).worker
      end

      states :created, :starting, :waiting, :working, :stopping, :errored, :stopped

      event :start, :from => :created, :to => :waiting
      event :work,  :from => :waiting, :to => :waiting
      event :stop,  :to => :stopped
      event :error, :to => :errored

      attr_accessor :state

      attr_reader :name, :vm, :queue, :reporter, :logger, :config, :payload, :last_error

      # Instantiates a new worker.
      #
      # queue - The MessagingHub used to subscribe to the builds queue.
      # vm    - The virtual machine to be used by the worker.
      def initialize(name, vm, queue, reporter, logger, config)
        @name     = name
        @vm       = vm
        @queue    = queue
        @reporter = reporter
        @logger   = logger
        @config   = config
      end

      # Boots the worker by preparing the VM and subscribing to the builds queue.
      #
      # Returns self.
      def start
        self.state = :starting
        heart.beat
        vm.prepare
        queue.subscribe(:ack => true, :blocking => false, &method(:process))
        self
      end
      log :start

      # Processes a build message payload.
      #
      # This method also changes the state of the Worker to :workering while processing the
      # job, and saves the current payload to payload for introspection during the
      # build process.
      #
      # Returns true.
      #
      # Raises WorkerError if there was an error processing the job.
      def process(message, payload)
        work(message, payload)
      rescue Errno::ECONNREFUSED, Exception => error
        error(error, message)
      end
      log :process, :params => false

      # Stops the worker by cancelling the builds queue subscription.
      def stop(options = {})
        self.state = :stopping unless errored?
        queue.cancel_subscription
        kill if options[:force]
      end
      log :stop

      # Forcefully stops the current job
      def kill
        vm.shell.terminate('The worker was stopped forcefully')
      end

      protected

        def heart
          @heart ||= Heart.new(self) { |type, data| reporter.message(type, data) }
        end

        def work(message, payload)
          prepare(payload)
          Build.create(vm, vm.shell, reporter, payload, config).run
          finish(message)
          true
        end

        def prepare(payload)
          self.state = :working
          @payload = decode(payload)
        end
        log :start

        def finish(message)
          @payload = nil
          message.ack
        end
        log :finish, :params => false

        def error(error, message)
          self.state = :errored
          @last_error = error
          log_error(error)
          message.ack(:requeue => true)
          stop
        end
        log :error

        def decode(payload)
          Hashr.new(MultiJson.decode(payload))
        end
    end
  end
end
