require 'hot_bunnies'

module Travis
  module Worker
    class Application
      extend Util::Logging

      def start
        install_signal_traps
        manager.start
      end
      log :start

      def stop(workers, options)
        call_remote(:stop, options.merge(:workers => workers))
      end

      def terminate(options)
        call_remote(:terminate, options)
      end

      protected

        def manager
          @manager ||= Manager.create
        end

        def logger
          @logger ||= Logger.new('app')
        end

        def install_signal_traps
          Signal.trap('INT')  { manager.quit }
          Signal.trap('TERM') { manager.quit }
        end
        log :install_signal_traps

        def call_remote(command, options)
          Amqp.commands.publish(options.merge(:command => command))
          Amqp.disconnect
        end
        log :call_remote
    end
  end
end
