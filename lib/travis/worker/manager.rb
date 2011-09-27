module Travis
  module Worker
    class Manager

      attr_reader :worker_threads, :messaging_connection, :configuration

      def initialize(configuration, messaging_connection)
        @worker_threads = []
        @configuration = configuration
        @messaging_connection = messaging_connection
      end

      def start
        messaging_connection.bind
        start_workers
      end

      def stop
        workers.each { |worker| worker.value.stop_processing }
        messaging_connection.unbind
      end

      def start_workers
        configuration.vms.count.times do |num|
          puts "[boot] Starting worker number #{num}"

          worker_name = "#{configuration.vms.name_prefix}-#{num}"
          builds_queue, channel = messaging_connection.builds_queue, messaging_connection.channel

          worker_threads << Worker.start_in_background(worker_name, builds_queue, channel)
        end
      end

    end
  end
end