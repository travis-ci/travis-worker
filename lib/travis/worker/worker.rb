require 'multi_json'
require 'hashr'
require 'hot_bunnies'
require 'thread'

module Travis
  module Worker

    # Represents a single Worker which is bound to a single VM instance.
    class Worker
      include Util::Logging

      # Returns the string name of the worker.
      attr_reader :name

      # Returns the messaging hub used for builds queue
      attr_reader :messaging_hub

      # Returns the virtual machine used by this worker
      attr_reader :virtual_machine

      # Instantiates and a new worker.
      #
      # name - The String name of the worker.
      # jobs_queue - The Queue where jobs are published to.
      # reporting_channel - The Channel used for reporting build results.
      #
      # Returns the thread containing the worker.
      def initialize(name)
        @name = name
        @messaging_hub = Messaging.hub('builds')
        @virtual_machine = VirtualMachine::VirtualBox.new(name)
      end

      # Subscribes to the jobs_queue.
      #
      # Returns the worker.
      def run
        announce("Starting worker #{name}")

        virtual_machine.prepare

        opts = { :ack => true, :blocking => false }

        messaging_hub.subscribe(opts) do |meta, payload|
          begin
            process_job(meta, payload)
          rescue => e
            puts e.inspect
          end
        end

        announce("Subscribed to the '#{messaging_hub.name}' queue.")

        self
      end

      # Processes the build job using the messaging payload.
      #
      # metadata - The Headers from the messaging backend
      # payload - The String payload.
      #
      # If the job fails due to the VM not being found, or if the ssh connection
      # encounters an error, then the job is requeued and the error is reraised.
      #
      # Returns true if the job completed correctly, or false if it fails
      # Raises VmNotFound if the VM can not be found
      # Raises Errno::ECONNREFUSED if the SSH connection is refused
      def process_job(metadata, payload)
        Thread.current[:logging_header] = logging_header

        deserialized = deserialized_payload(payload)

        create_job_and_work(deserialized)

        confirm_job_completion(metadata)

        true
      rescue Travis::Worker::VirtualMachine::VmNotFound, Errno::ECONNREFUSED
        announce_error
        requeue(metadata)
        raise $!
      rescue Exception => e
        announce_error
        reject_job_completion(metadata)
        false
      end

      def stop
        messaging_hub.close
      end

      def logging_header
        name
      end

      private

        # Internal: Creates a job from the payload and executes it.
        #
        # payload - The job payload.
        def create_job_and_work(payload)
          announce("Handling Job payload : #{payload.inspect}")
          Job.create(payload, virtual_machine).work!
          announce("Job Complete")
        end

        def confirm_job_completion(metadata)
          metadata.ack
          announce("Job marked as Acknowledged")
        end

        def reject_job_completion(metadata)
          announce("Caught an exception while dispatching a message:")
          announce_error
          metadata.reject
          announce("Job marked as Rejected")
        end

        def requeue(metadata)
          announce("#{$!.class.name}: #{$!.message}", $@)
          announce('Can not connect to VM. Stopping job processing and requeuing job...')
          metadata.reject(:requeue => true)
        end

        def deserialized_payload(payload)
          deserialized = MultiJson.decode(payload)
          Hashr.new(deserialized)
        end
    end

  end
end
