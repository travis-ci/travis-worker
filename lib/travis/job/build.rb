require 'pathname'

module Travis
  module Job
    # Clones/fetches the repository, installs the bundle and runs the build
    # scripts using the default or specified rvm ruby.
    class Build < Base
      attr_reader :status, :log

      def initialize(payload)
        super
        observers << self
        @log = ''
      end

      protected

        def perform
          @status = build! ? 0 : 1
          update(:log => "\nDone. Build script exited with: #{status}\n")
        end

        def start
          notify(:start, :started_at => Time.now)
        end

        def update(data)
          notify(:update, data)
        end

        def finish
          notify(:finish, :log => log, :status => status, :finished_at => Time.now)
        end

        def build!
          chdir do
            setup_env
            repository.checkout(build.commit)
            repository.install && run_scripts
          end
        end

        def setup_env
          exec "rvm use #{config.rvm || 'default'}"
          exec "BUNDLE_GEMFILE=#{config.gemfile}" if config.gemfile
          exec config.env if config.env
        end

        def run_scripts
          %w{before_script script after_script}.each do |type|
            script = config.send(type)
            break false if script && !run_script(script)
          end
        end

        def run_script(script)
          Array(script).each do |script|
            break false unless exec(script)
          end
        end

        def on_update(job, data)
          log << data[:log] if data.key?(:log)
        end
      end
  end
end
