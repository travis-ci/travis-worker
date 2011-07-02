require "thor"

require "travis/worker"
require "travis/worker/application"

module Travis
  module Worker


    class App < Thor
      desc "start", "Start worker"
      def start
        config     = Travis::Worker.config
        dispatcher = Application.new(config)
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
