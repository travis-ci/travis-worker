require 'hot_bunnies'

module Travis
  module Worker
    class Application
      extend Util::Logging

      attr_reader :manager, :logger

      def initialize
        @manager = Manager.create
        @logger  = Logger.new('application')
      end

      def start
        install_signal_traps
        manager.start
      end
      log :start

      def stop(workers, options)
        call_remote(:stop, :workers => workers, :options => options)
      end

      protected

        def install_signal_traps
          Signal.trap('INT')  { quit }
          Signal.trap('TERM') { quit }
        end
        log :install_signal_traps

        def quit
          manager.stop
          java.lang.Thread.sleep(500)
          java.lang.System.exit(0)
        end
        log :quit

        def call_remote(command, options)
          Amqp.control.publish({ :command => command}.merge(options))
          Amqp.disconnect
        end
        log :call_remote
    end
  end
end
