require 'multi_json'
require 'hot_bunnies'

module Travis
  module Worker

    class Worker
      # Public: Returns the string name of the worker.
      attr_reader :name

      # Public: Returns the builds queue which the worker subscribes to.
      attr_reader :builds_queue

      # Public: Returns the reporting channel used for streaming build results.
      attr_reader :reporting_channel

      class << self
        # Public: Instantiates and runs a worker in a new thread.
        #
        # name - The String name of the worker.
        # builds_queue - The Queue where builds are published to.
        # reporting_channel - The Channel used for reporting build results.
        #
        # Returns the thread containing the worker.
        def start_in_background(name, builds_queue, reporting_channel)
          Thread.new do
            self.new(name, builds_queue, reporting_channel).run
          end
        end
      end

      # Public: Instantiates and a new worker.
      #
      # name - The String name of the worker.
      # builds_queue - The Queue where builds are published to.
      # reporting_channel - The Channel used for reporting build results.
      #
      # Returns the thread containing the worker.
      def initialize(name, builds_queue, reporting_channel)
        @name = name
        @builds_queue = builds_queue
        @reporting_channel = reporting_channel
        @subscribtion = nil
      end

      # Public: Subscribes to the builds_queue.
      #
      # Returns the worker.
      def run
        opts = { :ack => true, :blocking => false }

        @subscribtion = builds_queue.subscribe(opts, &method(:process_job))

        announce("Subscribed to the '#{@builds_queue.name}' queue.")

        self
      end

      # Public: Unsubscribes from the builds_queue.
      #
      # Returns the worker.
      def stop
        @subscribtion.cancel
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
          job = Job.create(payload)
          job.observers << Reporter.new(reporting_channel)
          job.work!
        end

        def confirm_job_completion(metadata)
          metadata.ack
          announce("Acknowledged")
        end

        def reject_job_completion(metadata)
          announce("Caught an exception while dispatching a message: \n\n#{e.message}\n\n")
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

        def deserialized_payload
          deserialized = MultiJson.decode(payload)
          deserialized.deep_symbolize_keys
        end

        def announce_error
          announce("#{$!.class.name}: #{$!.message}", $@)
        end
    end

  end
end
