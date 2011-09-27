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
        stop_workers
        messaging_connection.unbind
      end


      protected

        def start_workers
          builds_queue = messaging_connection.builds_queue,
          channel = messaging_connection.channel

          configuration.vms.count.times do |num|
            name = worker_name(num)

            puts "[boot] Starting #{name}"

            worker_threads << Worker.start_in_background(name, builds_queue, channel)
          end
        end

        def stop_workers
          workers.each { |worker| worker.value.stop_processing }
        end

        def worker_name(num)
          "#{Travis::Worker.config.vms.name_prefix}-#{num}"
        end

    end
  end
end