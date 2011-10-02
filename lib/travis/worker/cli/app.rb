require "thor"
require 'travis/worker'

module Travis
  module Worker
    module Cli

      class App < Thor
        namespace 'travis:worker'

        desc "start", "Start worker manager"
        def start
          app = Travis::Worker::Application.new
          app.start
        end

        desc "stop", "Stop worker manager if running"
        def stop
          # TBD
        end

        desc "status", "Display status information"
        def status
          # TBT
        end
      end

    end
  end
end

