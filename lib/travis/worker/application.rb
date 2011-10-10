require "hot_bunnies"

module Travis
  module Worker
    class Application

      attr_reader :manager

      def initialize
        @manager = Manager.create
      end

      def start
        install_signal_traps

        announce("About to start the builds manager")

        manager.start
      end


      protected

        def install_signal_traps
          announce("About to install signal traps...")

          Signal.trap("INT")  { self.manager.stop; exit }
          Signal.trap("TERM") { self.manager.stop; exit }
        end

        def announce(what)
          puts "[boot] #{what}"
        end
    end
  end
end
