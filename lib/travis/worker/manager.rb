module Travis
  module Worker
    class WorkerNotFound < Exception; end

    # The Worker manager, responsible for starting, monitoring,
    # and stopping Worker instances.
    class Manager
      extend Util::Logging

      def self.create
        Manager.new(Travis::Worker.names, Amqp, Logger.new('manager'), Travis::Worker.config)
      end

      attr_reader :names, :amqp, :logger, :config

      # Initialize a Worker Manager.
      #
      # configuration - A Config to use for connection details (default: nil)
      def initialize(names, amqp, logger, config)
        @names  = names
        @amqp   = amqp
        @logger = logger
        @config = config

        # subscribe to control queue
      end

      # Connects to the messaging broker and start all workers.
      #
      # Returns the current manager instance.
      def start(names = [])
        names = self.names if names.empty?
        subscribe
        start_workers(names.flatten)
        self
      end

      # Disconnects from the messaging broker and stops all workers.
      #
      # Returns the current manager instance.
      def stop(names = [], options = {})
        names = self.names if names.empty?
        stop_workers(names, options)
        disconnect
        self
      end

      def status
        # worker state
        # current payload
        # last error
      end

      protected

        def subscribe
          amqp.control.subscribe(:ack => true, :blocking => false, &method(:process))
        end
        log :subscribe

        def disconnect
          amqp.disconnect
        end
        log :disconnect

        def process(message, payload)
          payload = decode(payload)
          send(payload.command, payload.workers, payload.options)
        end

        def start_workers(names)
          names.each { |name| worker(name).start }
        end
        log :start_workers

        def stop_workers(names, options)
          names.each { |name| worker(name).stop(options) }
        end
        log :stop_workers

        def workers
          @workers ||= names.map do |name|
            Worker.create(name, config)
          end
        end

        def worker(name)
          workers.detect { |worker| worker.name == name } || raise(WorkerNotFound.new(name))
        end

        def decode(payload)
          Hashr.new(MultiJson.decode(payload), :workers => [], :options => {})
        end
    end
  end
end
