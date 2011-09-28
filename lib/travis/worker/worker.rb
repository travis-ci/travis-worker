require 'multi_json'
require 'hashr'
require 'hot_bunnies'
require 'thread'

module Travis
  module Worker

    # Public: Represents a single Worker which is bound to a single VM instance.
    class Worker

      # Public: Returns the string name of the worker.
      attr_reader :name

      # Public: Returns the builds queue which the worker subscribes to.
      attr_reader :jobs_queue

      # Public: Returns the reporting channel used for streaming build results.
      attr_reader :reporting_channel

      # Public: Returns the Subscription to the jobs_queue
      attr_reader :subscribtion

      # Public: Returns the virtual machine used by this worker
      attr_reader :virtual_machine

      class << self
        # Public: Instantiates and runs a worker in a new thread.
        #
        # name - The String name of the worker.
        # jobs_queue - The Queue where builds are published to.
        # reporting_channel - The Channel used for reporting build results.
        #
        # Returns the thread containing the worker.
        def start_in_background(name, jobs_queue, reporting_channel)
          Thread.new do
            self.new(name, jobs_queue, reporting_channel).run
          end
        end
      end

      # Public: Instantiates and a new worker.
      #
      # name - The String name of the worker.
      # jobs_queue - The Queue where jobs are published to.
      # reporting_channel - The Channel used for reporting build results.
      #
      # Returns the thread containing the worker.
      def initialize(name, jobs_queue, reporting_channel)
        @name = name
        @jobs_queue = jobs_queue
        @reporting_channel = reporting_channel
        @subscription = nil
        @virtual_machine = VirtualMachine::VirtualBox.new(name)
      end

      # Public: Subscribes to the jobs_queue.
      #
      # Returns the worker.
      def run
        opts = { :ack => true, :blocking => false }

        @subscription = jobs_queue.subscribe(opts, &method(:process_job))

        announce("Subscribed to the '#{@jobs_queue.name}' queue.")

        self
      end

      # Public: Processes the build job using the messaging payload.
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
        deserialized = deserialized_payload(payload)

        announce("Handling #{deserialized.inspect}")

        create_job_and_work(deserialized)

        announce("Done")

        confirm_job_completion(metadata)

        true
      rescue VmNotFound, Errno::ECONNREFUSED
        announce_error
        requeue(metadata)
        raise $!
      rescue Exception => e
        announce_error
        reject_job_completion(metadata)
        false
      ensure
        Travis::Worker.discard_shell!
      end


      private

        # Internal: Creates a job from the payload and executes it.
        #
        # payload - The job payload.
        #
        # Returns ?
        def create_job_and_work(payload)
          job = Job.create(payload, virtual_machine)
          job.observers << Reporter.new(reporting_channel)
          job.work!
        end

        def confirm_job_completion(metadata)
          metadata.ack
          announce("Acknowledged")
        end

        def reject_job_completion(metadata)
          announce("Caught an exception while dispatching a message:")
          announce_error
          metadata.reject
          announce("Rejected")
        end

        def requeue(metadata)
          announce("#{$!.class.name}: #{$!.message}", $@)
          announce('Can not connect to VM. Stopping job processing ...')
          metadata.reject(:requeue => true)
        end

        def announce(what)
          puts "[#{name}] #{what}"
        end

        def deserialized_payload(payload)
          deserialized = MultiJson.decode(payload)
          Hashr.new(deserialized)
        end

        def announce_error
          announce("#{$!.class.name}: #{$!.message}")
          announce($@)
        end
    end

  end
end
