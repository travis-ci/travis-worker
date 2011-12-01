require 'hot_bunnies'

module Travis
  class Worker
    class Application
      autoload :Command, 'travis/worker/application/command'
      autoload :Heart,   'travis/worker/application/heart'
      autoload :Remote,  'travis/worker/application/remote'

      include Logging

      def initialize
        Travis.logger.level = Logger.const_get(config.log_level.to_s.upcase) # TODO hrmm ...
        Travis::Amqp.config = config.amqp
      end

      def boot(options = {})
        install_signal_traps
        start(options)
        heart.beat
        Command.subscribe(self)
      end
      log :boot

      def start(options = {})
        workers.start(options[:workers] || [])
      end
      log :start

      def stop(options = {})
        workers.stop(options.delete(:workers) || [], options)
      end
      log :stop

      def status(*)
        workers.status
      end

      def set(config)
        config.each { |path, value| self.config.set(path, value) }
      end

      def terminate(options = {})
        stop(options)
        disconnect
        update if options[:update]
        reboot if options[:reboot]
        quit
      end
      log :terminate

      protected

        def config
          Travis::Worker.config
        end

        def workers
          @workers ||= Pool.create
        end

        def heart
          @heart ||= Heart.new { workers.status }
        end

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
          system('echo "thor travis:worker:boot >> log/worker.log" | at now')
          info "reboot scheduled"
        end

        def execute(commands)
          commands.split("\n").each do |command|
            info(command.strip)
            system("#{command.strip} >> log/worker.log")
          end
        end

        def disconnect
          heart.stop
          Amqp.disconnect
          sleep(0.5)
        end
        log :disconnect

        def quit
          java.lang.System.exit(0)
        end

        def install_signal_traps
          Signal.trap('INT')  { quit }
          Signal.trap('TERM') { quit }
        end
    end
  end
end
