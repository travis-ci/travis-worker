require 'travis/build'
require 'simple_states'
require 'multi_json'
require 'thread'

module Travis
  module Worker
    # Represents a single Worker which is bound to a single VM instance.
    class Worker
      autoload :JobFactory, 'travis/worker/worker/job_factory'

      include SimpleStates
      extend Logging

      states :created, :booting, :waiting, :working, :stopped

      event :boot, :to => :waiting
      event :work, :to => :waiting
      event :stop, :to => :stopped

      attr_accessor :state
      attr_reader :vm, :queue, :jobs, :payload, :last_error, :logger

      # Instantiates a new worker.
      #
      # queue      - The MessagingHub used to subscribe to the builds queue.
      # vm - The virtual machine to be used by the worker.
      def initialize(queue, vm)
        @queue = queue
        @vm = vm
        @jobs = JobFactory.new(vm)
        @logger = Logging::Logger.new(vm.name)
      end

      # Boots the worker by preparing the VM and subscribing to the builds queue.
      #
      # Returns self.
      def boot
        self.state = :booting
        vm.prepare
        queue.subscribe(:ack => true, :blocking => false, &method(:work))
        self
      end

      # Processes a build message payload.
      #
      # This method also changes the state of the Worker to :workering while processing the
      # job, and saves the current payload to payload for introspection during the
      # build process.
      #
      # Returns true.
      def work(message, payload)
        start(payload)
        process
        finish(message)
        true
      rescue Errno::ECONNREFUSED, Exception => error
        error(error, message)
        false
      end

      # Stops the worker by cancelling the builds queue subscription.
      def stop
        queue.cancel_subscription
      end
      log :stop

      protected

        def start(payload)
          self.state = :working
          @payload = decode(payload)
        end
        log :start

        def finish(message)
          @payload = nil
          message.ack
        end
        log :finish

        def error(error, message)
          log_error(error)
          message.ack(:requeue => true)
          @last_error = error
          stop
        end
        log :error

        def process
          jobs.create(payload).run
        end

        def decode(payload)
          Hashr.new(MultiJson.decode(payload))
        end
    end
  end
end
