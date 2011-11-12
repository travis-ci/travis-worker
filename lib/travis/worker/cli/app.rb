require 'thor'
require 'travis/worker'

module Travis
  module Worker
    module Cli
      class App < Thor
        namespace 'travis:worker'

        desc 'start', 'Start the manager and workers'
        def start
          app.start
        end

        desc 'terminate', 'Stop all workers and the manager'
        method_option :force,  :aliases => '-f', :type => :boolean, :default => false, :desc => 'Forcefully terminate the current build(s)'
        def status
          app.terminate(:force => options['force'])
        end

        desc 'stop', 'Stop workers'
        method_option :force,  :aliases => '-f', :type => :boolean, :default => false, :desc => 'Forcefully terminate the current build(s)'
        def stop(*workers)
          app.stop(workers, :force => options['force'])
        end

        desc 'status', 'Display status information'
        def status
          # TBT
        end

        protected

          def app
            @app ||= Travis::Worker::Application.new
          end
      end
    end
  end
end

