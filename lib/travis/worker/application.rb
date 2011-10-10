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
          Signal.trap("INT")  { puts "Handling SIGINT...";  self.quit }
          Signal.trap("TERM") { puts "Handling SIGTERM..."; self.quit }
        end
        log :install_signal_traps

        def quit
          self.manager.stop
          sleep(3) # give all threads a little time to stop completely
          exit
        end
        log :quit
    end
  end
end
