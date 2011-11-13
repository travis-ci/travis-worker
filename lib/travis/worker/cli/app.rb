require 'thor'
require 'travis/worker'

module Travis
  module Worker
    module Cli
      class App < Thor
        namespace 'travis:worker'

        desc 'boot', 'Boot the manager and start workers'
        def boot(*workers)
          app.boot(workers)
        end

        desc 'terminate', 'Stop all workers and the manager'
        method_option :force,  :aliases => '-f', :type => :boolean, :default => false, :desc => 'Forcefully terminate the current build(s)'
        def terminate
          app.terminate(:force => options['force'])
        end

        desc 'start', 'Start workers'
        def start(*workers)
          app.start(workers)
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

