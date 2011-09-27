require "multi_json"

module Travis
  module Worker
    class Worker

      def self.start_in_background(worker_name, builds_queue, reporting_channel)
        Thread.new do
          self.new(worker_name, builds_queue, reporting_channel).run
        end
      end

      attr_reader :worker_name, :builds_queue, :reporting_channel

      def initialize(worker_name, builds_queue, reporting_channel)
        @worker_name  = worker_name
        @builds_queue = builds_queue
        @reporting_channel = reporting_channel
      end

      def run
        builds_queue.subscribe(:ack => true, :blocking => false, &method(:handle_message))

        announce("[#{worker_name}] Subscribed to the '#{@builds_queue.name}' queue.")

        self
      end

      def handle_message(metadata, payload)
        begin
          deserialized = MultiJson.decode(payload)
          announce("[#{worker_name}] Handling #{deserialized.inspect}")

          reporter = Reporter.new(reporting_channel)

          Runner.new(metadata, deserialized, reporter).work!

          announce("[#{worker_name}] Done")
          metadata.ack
          announce("[#{worker_name}] Acknowledged")
        rescue Exception => e
          announce("[#{worker_name}] Caught an exception while dispatching a message: \n\n#{e.message}\n\n")
          metadata.reject
          announce("[#{worker_name}] Rejected")
        end
      end


      protected

        def announce(what)
          puts what
        end

    end
  end
end
