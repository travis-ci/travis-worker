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
        update if options[:update]
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
        log :disconnect

        def update
          execute <<-sh
            git reset --hard
            git pull
            bundle install
          sh
        end
        log :update

        def reboot
          # unfortunately fork is not available on jruby
          # system('nohup thor travis:worker:boot > log/worker.log &') if fork.nil?
          #
          # on mac osx atd is disabled:
          # http://superuser.com/questions/43678/mac-os-x-at-command-not-working
          system('echo "thor travis:worker:boot >> log/worker.log" | at now')
          info "reboot scheduled"
        end

        def execute(commands)
          commands.split("\n").each do |command|
            info(command.strip)
            system("#{command.strip} > log/worker.log")
          end
        end
    end
  end
end
