require 'travis/build'
require 'simple_states'
require 'multi_json'
require 'thread'

module Travis
  module Worker

    # Represents a single Worker which is bound to a single VM instance.
    class Worker
      include SimpleStates
      include Util::Logging

      states :created, :booting, :waiting, :working, :stopped

      event :boot,   :from => :created, :to => :waiting
      event :work,   :from => :waiting, :to => :waiting
      event :stop,   :to => :stopped

      # Required by SimpleStates
      attr_accessor :state


      # Returns the MessageHub used to subscribe to the builds queue.
      attr_reader :builds_hub

      # Returns the virtual machine used exclusivly by this worker.
      attr_reader :virtual_machine

      # Returns the current job payload being processed.
      attr_reader :job_payload

      # Returns the reason (Symbol) that the worker was stopped.
      attr_reader :stopped_reason

      # Returns the last error if the last job resulted in an error.
      attr_reader :last_error


      # Instantiates a new worker.
      #
      # builds_hub      - The MessagingHub used to subscribe to the builds queue.
      # virtual_machine - The virtual machine to be used by the worker.
      def initialize(builds_hub, virtual_machine)
        @builds_hub = builds_hub
        @virtual_machine = virtual_machine
      end

      # Boots the worker by preparing the VM and subscribing to the builds queue.
      #
      # Returns self.
      def boot
        self.state = :booting
        virtual_machine.prepare
        builds_hub.subscribe(:ack => true, :blocking => false) do |meta, payload|
          begin
            work(meta, payload)
          rescue Errno::ECONNREFUSED, Exception => error
            error(error, meta)
            false
          end
        end
        self
      end

      # Processes a build message payload.
      #
      # This method also changes the state of the Worker to :workering while processing the
      # job, and saves the current payload to job_payload for introspection during the
      # build process.
      #
      # Returns true if the job was processed successfully.
      def work(metadata, payload)
        start(payload)
        process
        finish(metadata)
        true
      end

      # Stops the worker by cancelling the builds queue subscription.
      def stop
        announce("Stopping Worker for accepting further jobs")
        builds_hub.cancel_subscription if builds_hub
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
          announce_error
          metadata.ack(:requeue => true) if metadata
          @stopped_reason = :fatal_error
          @last_error = error
          stop
        end

        # Internal: Creates a job from the job_payload and executes it.
        def process
          announce("Handling Job payload : #{job_payload.inspect}")

          http  = Build::Connection::Http.new(Travis::Worker.config) # could probably reuse this connection, no?
          shell = virtual_machine.shell
          job = Build::Job.runner(virtual_machine, shell, http, job_payload, Reporter.new)
          job.run

          announce("Job Complete")
        end

        def set_logging_header
          Thread.current[:logging_header] = virtual_machine.name
        end

        def decode(payload)
          Hashr.new(MultiJson.decode(payload))
        end
    end

  end
end
