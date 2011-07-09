require "thor"
require 'travis/worker'

module Travis
  module Worker
    module Cli
      class App < Thor
        namespace 'travis:worker'


        desc "start", "Start worker"
        def start
          config     = Travis::Worker.config
          dispatcher = Travis::Worker::Application.new(config)
          dispatcher.bind(config.amqp.to_hash.deep_symbolize_keys)
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
    end
  end # Worker
end # Travis

