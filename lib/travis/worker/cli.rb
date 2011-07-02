require "thor"

require "travis/worker"
require "travis/worker/dispatcher"

module Travis
  module Worker


    class App < Thor
      desc "start", "Start worker"
      def start
        config     = Travis::Worker.config
        dispatcher = Dispatcher.new(config)
        dispatcher.bind(config.amqp)
      end



      desc "stop", "Stop worker if running"
      def stop
        # TBD
      end



      desc "status", "Display status information"
      def status
        # TBT
      end
    end


  end # Worker
end # Travis
