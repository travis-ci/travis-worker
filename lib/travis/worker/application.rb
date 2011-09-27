require "hot_bunnies"

module Travis
  module Worker
    class Application

      attr_reader :manager, :configuration

      def initialize(configuration)
        @configuration = configuration

        @manager = Manager.new(messaging_connection)
      end

      def start
        install_signal_traps

        announce "[boot] About to start the builds manager"

        @manager.start
      end


      protected

        def install_signal_traps
          announce "[boot] About to install signal traps..."

          Signal.trap("INT")  { self.manager.stop }
          Signal.trap("TERM") { self.manager.stop }
        end

        def announce(what)
          puts what
        end

    end
  end
end
