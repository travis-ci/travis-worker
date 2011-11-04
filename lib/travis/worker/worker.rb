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

      states :created, :starting, :waiting, :working, :stopped

      event :start, :from => :created, :to => :waiting
      event :work,  :from => :waiting, :to => :waiting
      event :stop,  :to => :stopped

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
        queue.subscribe(:ack => true, :blocking => false, &method(:work_wrapper))
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
      def work(message, payload)
        prepare(payload)
        process
        finish(message)
        true
      rescue Errno::ECONNREFUSED, Exception => error
        error(error, message)
      end
      log :work, :params => false

      # Stops the worker by cancelling the builds queue subscription.
      def stop(options = {})
        heart.stop
        queue.cancel_subscription
        kill_jobs if options[:force]
      end
      log :stop

      protected

        def heart
          @heart ||= Heart.new(name) { |type, data| reporter.message(type, data) }
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
          log_error(error)
          message.ack(:requeue => true)
          @last_error = error
          stop
          raise WorkerError, "Error occured during job processing", error.backtrace
        end
        log :error

        def process
          Build.create(vm, vm.shell, reporter, payload, config).run
        end

        def kill_jobs
          vm.shell.terminate('The worker was stopped forcefully')
        end

        # Internal: This method is just a simple wrapper around work, silently catching
        # WorkerError.
        def work_wrapper(message, payload)
          work(message, payload)
        rescue WorkerError
          # do nothing
        end

        def decode(payload)
          Hashr.new(MultiJson.decode(payload))
        end
    end
  end
end
