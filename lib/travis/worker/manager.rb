module Travis
  module Worker

    # The Worker manager, responsible for starting, monitoring,
    # and stopping Worker instances.
    class Manager

      # Returns an Array of Worker instances.
      attr_reader :workers


      # Initialize a Worker Manager.
      #
      # configuration - A Config to use for connection details (default: nil)
      def initialize(config = nil)
        @config = config
        @workers = []
      end

      # Connects to the messaging broker and starts the workers.
      #
      # Returns the current instance of the MessagingConnection.
      def start
        connect_messaging
        start_workers
        self
      end

      # Disconnects from the messaging broker and stops all the workers.
      #
      # Returns the current instance of the MessagingConnection.
      def stop
        stop_workers
        disconnect_messaging
        self
      end


      protected

        # Internal: Starts new workers in new threads.
        #
        # Returns the current instance of the MessagingConnection.
        def start_workers
          declare_queues

          worker_names = VirtualMachine::VirtualBox.vm_names

          worker_names.each do |name|
            announce("Starting #{name}")

            worker = Worker.create(name, config)
            workers << worker
            worker.run
          end

          self
        end

        def stop_workers
          workers.each { |worker| worker.cancel }
        end


      private

        def connect_messaging
          Messaging.connect
        end

        def disconnect_messaging
          Messaging.disconnect
        end

        def declare_queues
          Messaging.declare_queues('builds', 'reporting.jobs')
        end

        def config
          @config ||= Travis::Worker.config
        end
    end

  end
end
