require 'thor'
require 'travis/worker'
require 'hashr'

module Travis
  module Worker
    module Cli
      class App < Thor
        namespace 'travis:worker'

        desc 'boot', 'Boot the manager and start workers'
        def boot(*workers)
          require 'autoload_gauntlet'
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
          reports = Hashr.new(app.status)
          # TODO extract a formatter
          max_length = reports.keys.map(&:to_s).max_by { |name| name.length }.length

          puts "Current worker states:\n\n"
          puts reports.map { |worker, report|
            line = "#{"#{worker}:".ljust(max_length)} #{report.state}"
            line += " (#{report.payload.repository.slug} ##{report.payload.build.number})" if report.state == "working"
            line += " (#{report.last_error})" if report.state == "errored"
            line
          }
          puts
        end

        protected

          def app
            @app ||= Travis::Worker::Application.new
          end
      end
    end
  end
end

