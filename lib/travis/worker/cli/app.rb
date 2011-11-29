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
          preload_constants!
          app.boot(workers)
        end

        desc 'reboot', 'Reboot the manager and workers'
        method_option :force,  :aliases => '-f', :type => :boolean, :default => false, :desc => 'Forcefully terminate the current build(s)'
        def reboot
          app.terminate(:force => options['force'], :reboot => true)
        end

        desc 'update', 'Update the worker code and reboot the manager and workers'
        method_option :force,  :aliases => '-f', :type => :boolean, :default => false, :desc => 'Forcefully terminate the current build(s)'
        def update
          app.terminate(:force => options['force'], :reboot => true, :update => true)
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

        desc 'restart', 'Restart workers (forcefully terminates current builds)'
        def restart(*workers)
          app.stop(workers, :force => true)
          app.start(workers)
        end

        desc 'stop', 'Stop workers'
        method_option :force,  :aliases => '-f', :type => :boolean, :default => false, :desc => 'Forcefully terminate the current build(s)'
        def stop(*workers)
          app.stop(workers, :force => options['force'])
        end

        desc 'status', 'Display status information'
        method_option :watch,    :aliases => '-w', :type => :boolean, :default => false, :desc => 'Watch the worker status'
        method_option :interval, :aliases => '-i', :type => :numeric, :default => 2,     :desc => 'Refresh interval when watching the worker status'
        def status
          watching do
            print_status(app.status)
          end
        end

        desc 'config', 'Show the current Travis::Worker.config'
        def config
          p app.config
        end

        desc 'set', 'Set a value to Travis::Worker.config using a dot-separated path'
        def set(expression)
          app.set(parse(expression))
        end

        protected

          def app
            @app ||= Travis::Worker::Application::Remote.new
          end

          def preload_constants!
            require 'core_ext/module/load_constants'
            require 'travis/build'
            require 'faraday'

            [Travis::Worker, Travis::Build, Faraday].each do |target|
              target.load_constants!
            end
          end

          def watching
            if options['watch']
              # TODO install signal traps
              loop do
                yield
                sleep(options['interval'])
              end
            else
              yield
            end
          end

          def print_status(reports)
            reports = Hashr.new(reports)
            max_length = reports.keys.map(&:to_s).max_by { |name| name.length }.length

            puts "#{Time.now.utc}\n"
            puts "Current worker states:\n\n" # TODO extract a formatter
            puts reports.map { |worker, report|
              line = "#{"#{worker}:".ljust(max_length)} #{report.state}"
              line += " (#{report.payload.repository.slug} ##{report.payload.build.number})" if report.payload? && report.payload.repository?
              line += " (#{report.last_error})" if report.state == "errored"
              line
            }
            puts
          end

          def parse(expression)
            raise "the given argument needs to have the format dot.separated.path=value" unless expression =~ /[^=]+=[^=]+/
            path, value = expression.split('=')
            { path => eval(value) }
          end
      end
    end
  end
end

