require "hot_bunnies"

module Travis
  module Worker
    class Application
      extend Util::Logging

      attr_reader :manager, :logger

      def initialize
        @manager = Manager.create
        @logger  = Util::Logging::Logger.new('boot')
      end

      def start
        install_signal_traps
        manager.start
      end
      log :start

      protected

        def install_signal_traps
          Signal.trap("INT")  { quit }
          Signal.trap("TERM") { quit }
        end
        log :install_signal_traps

        def quit
          self.manager.stop
          java.lang.Thread.sleep(500)
          java.lang.System.exit(0)
        end
        log :quit
    end
  end
end
