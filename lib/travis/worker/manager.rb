require 'java'

module Travis
  module Worker
    class WorkerNotFound < Exception
      def initialize(name)
        super "Unknown worker #{name}"
      end
    end

    # The Worker manager, responsible for starting, monitoring,
    # and stopping Worker instances.
    class Manager
      include Logging

      def self.create
        Manager.new(Travis::Worker.names, Amqp, Travis::Worker.config) # Logger.new('manager'),
      end

      attr_reader :names, :amqp, :config

      def initialize(names, amqp, config)
        @names  = names
        @amqp   = amqp
        @config = config
      end

      def start(options = {})
        names = options.delete(:workers) || self.names
        names = self.names if names.empty?
        names.each { |name| worker(name).start }
      end
      log :start

      def stop(options = {})
        names = options.delete(:workers) || self.names
        names = self.names if names.empty?
        names.each { |name| worker(name).stop(options) }
      end
      log :stop

      def terminate(options = {})
        stop(options)
        disconnect
        reboot if options[:reboot]
        quit
      end
      log :terminate

      def status(options = {})
        workers.inject({}) do |result, worker|
          result.merge(worker.name => worker.report)
        end
      end

      def set(config)
        config.each { |path, value| self.config.set(path, value) }
      end

      def quit
        java.lang.System.exit(0)
      end

      protected

        def workers
          @workers ||= names.map { |name| Worker.create(name, config) }
        end

        def worker(name)
          workers.detect { |worker| worker.name == name } || raise(WorkerNotFound.new(name))
        end

        def disconnect
          amqp.disconnect
          java.lang.Thread.sleep(500)
        end

        def reboot
          system('nohup thor travis:worker:boot > log/worker.log &') if fork.nil?
        end
    end
  end
end
