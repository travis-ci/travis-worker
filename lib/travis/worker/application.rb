require "hot_bunnies"

module Travis
  module Worker
    class Application

      attr_reader :manager, :config

      def initialize(config = nil)
        @config = config

        @manager = Manager.new(configuration)
      end

      def start
        install_signal_traps

        announce("About to start the builds manager")

        manager.start
      end


      protected

        def configuration
          @config ||= Travis::Worker.config
        end

        def install_signal_traps
          announce("About to install signal traps...")

          Signal.trap("INT")  { self.manager.stop }
          Signal.trap("TERM") { self.manager.stop }
        end

        def announce(what)
          puts "[boot] #{what}"
        end

    end
  end
end
