module Travis
  module Worker
    class WorkerNotFound < Exception; end

    # The Worker manager, responsible for starting, monitoring,
    # and stopping Worker instances.
    class Manager
      include Util::Logging

      def self.create
        Manager.new(Travis::Worker.names, Amqp, Logger.new('manager'), Travis::Worker.config)
      end

      attr_reader :names, :amqp, :logger, :config

      def initialize(names, amqp, logger, config)
        @names  = names
        @amqp   = amqp
        @logger = logger
        @config = config
      end

      def start(options = {})
        names = options.delete(:workers) || self.names
        names.each { |name| worker(name).start }
      end
      log :start

      def stop(options = {})
        names = options.delete(:workers) || self.names
        names.each { |name| worker(name).stop(options) }
      end
      log :stop

      def terminate(options = {})
        stop(options)
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

        def disconnect
          amqp.disconnect
        end

        def workers
          @workers ||= names.map { |name| Worker.create(name, config) }
        end

        def worker(name)
          workers.detect { |worker| worker.name == name } || raise(WorkerNotFound.new(name))
        end
    end
  end
end
