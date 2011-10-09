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
      include Util::Logging

      states :created, :booting, :waiting, :working, :stopped

      event :boot, :to => :waiting
      event :work, :to => :waiting
      event :stop, :to => :stopped

      # Required by SimpleStates
      attr_accessor :state

      # Returns the MessageHub used to subscribe to the builds queue.
      attr_reader :queue

      # Returns the virtual machine used exclusivly by this worker.
      attr_reader :vm

      # Returns the current job payload being processed.
      attr_reader :job_payload

      # Returns the reason (Symbol) that the worker was stopped.
      attr_reader :stopped_reason

      # Returns the last error if the last job resulted in an error.
      attr_reader :last_error

      attr_reader :jobs


      # Instantiates a new worker.
      #
      # queue      - The MessagingHub used to subscribe to the builds queue.
      # vm - The virtual machine to be used by the worker.
      def initialize(queue, vm)
        @queue = queue
        @vm = vm
        @jobs = JobFactory.new(vm)
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
      # job, and saves the current payload to job_payload for introspection during the
      # build process.
      #
      # Returns true.
      def work(metadata, payload)
        start(payload)
        process
        finish(metadata)
        true
      rescue Errno::ECONNREFUSED, Exception => error
        error(error, metadata)
        false
      end

      # Stops the worker by cancelling the builds queue subscription.
      def stop
        announce("Stopping Worker for accepting further jobs")
        queue.cancel_subscription if queue
      end

      protected

        def start(payload)
          set_logging_header
          self.state = :working
          @job_payload = decode(payload)
        end

        def finish(metadata)
          @job_payload = nil
          metadata.ack
        end

        def error(error, metadata = nil)
          announce_error(error)
          metadata.ack(:requeue => true) if metadata
          @stopped_reason = :fatal_error
          @last_error = error
          stop
        end

        # Internal: Creates a job from the job_payload and executes it.
        def process
          announce("Handling Job payload : #{job_payload.inspect}")
          jobs.create(job_payload).run
          announce("Job Complete")
        end

        def set_logging_header
          # this seems to keep rspec/jruby from exiting?
          # Thread.current[:logging_header] = vm.name
        end

        def decode(payload)
          Hashr.new(MultiJson.decode(payload))
        end
    end
  end
end
