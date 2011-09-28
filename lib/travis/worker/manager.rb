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
      # configuration - A Config to use for connection details (default: nil)
      def initialize(configuration = nil)
        config(configuration)
        @worker_threads = []
        @messaging_connection = MessagingConnection.new(config)
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
          jobs_queue = messaging_connection.jobs_queue
          channel    = messaging_connection.channel

          config.vms.count.times do |num|
            num += 1
            name = worker_name(num)

            puts "[boot] Starting #{name}"

            worker_threads << Worker.start_in_background(name, jobs_queue, channel)
          end

          self
        end

        # Internal: Stops all current Worker instances, along with the thread
        # they are running in.
        def stop_workers
          worker_threads.each do |thread|
            thread.stop if thread.alive?
          end
        end


      private

        def config(configuration = nil)
          @config ||= configuration || Travis::Worker.config
          @config
        end

        def worker_name(num)
          "#{config.vms.name_prefix}-#{num}"
        end
    end

  end
end