require 'hot_bunnies'

module Travis
  module Worker
    class Application
      autoload :Command, 'travis/worker/application/command'
      autoload :Remote,  'travis/worker/application/remote'

      include Logging

      def boot(workers = [])
        setup
        install_signal_traps
        manager.start(workers)
        Command.subscribe(self)
      end

      protected

        def setup
          Travis.logger.level = Logger.const_get(Travis::Worker.config.log_level.to_s.upcase) # TODO hrmm ...
        end

        def manager
          @manager ||= Manager.create
        end

        def install_signal_traps
          Signal.trap('INT')  { manager.quit }
          Signal.trap('TERM') { manager.quit }
        end
    end
  end
end
