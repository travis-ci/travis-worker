module Travis
  module Worker
    class WorkerNotFound < Exception; end

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

      # Connects to the messaging broker and start all workers.
      #
      # Returns the current manager instance.
      def start(*names)
        names = worker_names if names.empty?
        connect_messaging
        start_workers(names.flatten)
        self
      end

      # Disconnects from the messaging broker and stops all workers.
      #
      # Returns the current manager instance.
      def stop(*names)
        names = worker_names if names.empty?
        stop_workers(names.flatten)
        disconnect_messaging
        self
      end

      def status
        # worker state
        # current payload
        # last error
      end

      protected

        def start_workers(names)
          names.each do |name|
            worker(name).start
          end
        end
        log :start_workers

        def stop_workers(names)
          options = names.last.is_a?(Hash) ? names.pop : {}
          names.each do |name|
            worker(name).stop(options)
          end
        end
        log :stop_workers

        def workers
          @workers ||= worker_names.map do |name|
            Worker.create(name, config)
          end
        end

        def worker(name)
          workers.detect { |worker| worker.name == name } || raise(WorkerNotFound.new(name))
        end

        def connect_messaging
          messaging.connect('builds', 'reporting.jobs')
        end
        log :connect_messaging

        def disconnect_messaging
          messaging.disconnect
        end
        log :disconnect_messaging
    end
  end
end
