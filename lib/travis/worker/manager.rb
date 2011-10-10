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
      end

      # Connects to the messaging broker and starts the workers.
      #
      # Returns the current instance of the MessagingConnection.
      def start
        connect_messaging
        declare_queues
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

        def start_workers
          workers.each do |worker|
            worker.boot
            worker.start
          end
        end
        # log :start_workers

        def stop_workers
          workers.each do |worker|
            worker.stop
          end
        end
        # log :stop_workers

        def workers
          @workers ||= worker_names.map do |name|
            Worker.create(name, config)
          end
        end

        def worker_names
          @worker_names ||= VirtualMachine::VirtualBox.vm_names
        end

        def connect_messaging
          Messaging.connect
        end
        # log :connect_messaging

        def disconnect_messaging
          Messaging.disconnect
        end
        # log :disconnect_messaging

        def declare_queues
          Messaging.declare_queues('builds', 'reporting.jobs')
        end
        # log :declare_queues

        def config
          @config ||= Travis::Worker.config
        end
    end
  end
end
