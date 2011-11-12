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
      end

      # Connects to the messaging broker and start the given workers.
      def start(options = {})
        start_workers(options.delete(:workers) || self.names)
        subscribe
      end
      log :start

      # Disconnects from the messaging broker and stops the given workers.
      def stop(options = {})
        stop_workers(options.delete(:workers) || self.names, options)
      end
      log :stop

      def terminate
        stop
        disconnect
        quit
      end
      log :terminate

      def status
        # worker state
        # current payload
        # last error
      end

      def quit
        java.lang.Thread.sleep(500)
        java.lang.System.exit(0)
      end

      protected

        def subscribe
          amqp.commands.subscribe(:ack => true, :blocking => false, &method(:process))
        end

        def disconnect
          amqp.disconnect
        end

        def process(message, payload)
          message.ack # TODO shouldn't need to ack here, right?
          payload = decode(payload)
          send(payload.delete(:command), payload)
        end

        def start_workers(names)
          names.each { |name| worker(name).start }
        end

        def stop_workers(names, options)
          names.each { |name| worker(name).stop(options) }
        end

        def workers
          @workers ||= names.map do |name|
            Worker.create(name, config)
          end
        end

        def worker(name)
          workers.detect { |worker| worker.name == name } || raise(WorkerNotFound.new(name))
        end

        def decode(payload)
          Hashr.new(MultiJson.decode(payload), :workers => [])
        end
    end
  end
end
