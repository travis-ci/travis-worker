module Travis
  module Worker

    # Public: The Worker manager, responsible for starting, monitoring,
    # and stopping Worker instances.
    class Manager

      # Public: Returns an Array of threads of Worker instances.
      attr_reader :worker_threads

      # Public: Returns the MessagingConnection used by the Manager.
      attr_reader :messaging_connection

      # Public: Initialize a Worker Manager.
      #
      # messaging_connection - A MessagingConnection instance.
      # config - A Config to use for connection details (default: nil)
      def initialize(messaging_connection, config = nil)
        @worker_threads = []
        @messaging_connection = messaging_connection
        @config = config
      end

      # Public: Connects to the messaging broker and starts the workers.
      #
      # Returns the current instance of the MessagingConnection.
      def start
        messaging_connection.bind
        start_workers
        self
      end

      # Public: Disconnects from the messaging broker and stops all the workers.
      #
      # Returns the current instance of the MessagingConnection.
      def stop
        stop_workers
        messaging_connection.unbind
        self
      end


      protected

        # Internal: Starts new workers in new threads.
        #
        # Returns the current instance of the MessagingConnection.
        def start_workers
          builds_queue = messaging_connection.builds_queue
          channel = messaging_connection.channel

          config.vms.count.times do |num|
            name = worker_name(num)

            puts "[boot] Starting #{name}"

            worker_threads << Worker.start_in_background(name, builds_queue, channel)
          end

          self
        end

        # Internal: Stops all current Worker instances, along with the thread
        # they are running in.
        def stop_workers
          worker_threads.each do |thread|
            thread.value.stop_processing
            thread.stop
          end
        end


      private

        def config
          @config ||= Travis::Worker.config
        end

        def worker_name(num)
          "#{config.vms.name_prefix}-#{num}"
        end
    end

  end
end