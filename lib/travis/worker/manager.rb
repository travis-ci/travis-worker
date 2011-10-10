module Travis
  module Worker
    # The Worker manager, responsible for starting, monitoring,
    # and stopping Worker instances.
    class Manager
      autoload :Factory, 'travis/worker/manager/factory'

      extend Util::Logging

      def self.create
        Factory.new.manager
      end

      attr_reader :worker_names, :messaging, :logger, :config

      # Initialize a Worker Manager.
      #
      # configuration - A Config to use for connection details (default: nil)
      def initialize(worker_names, messaging, logger, config)
        @worker_names = worker_names
        @messaging = messaging
        @logger = logger
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
        log :start_workers

        def stop_workers
          workers.each do |worker|
            worker.stop
          end
        end
        log :stop_workers

        def workers
          @workers ||= worker_names.map do |name|
            Worker.create(name, config)
          end
        end

        def connect_messaging
          messaging.connect
        end
        log :connect_messaging

        def disconnect_messaging
          messaging.disconnect
        end
        log :disconnect_messaging

        def declare_queues
          messaging.declare_queues('builds', 'reporting.jobs')
        end
        log :declare_queues
    end
  end
end
