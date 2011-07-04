require "travis/worker/job/base"

module Travis
  module Worker
    module Job
      # Build job implementation that uses the following workflow:
      #
      # * Clones/fetches the repository from {https://github.com GitHub}
      # * Installs dependencies using {http://gembundler.com Bundler}
      # * Switches to the default or specified Ruby implementation with {https://rvm.beginrescueend.com RVM}
      # * Runs one or more build scripts
      #
      # @see Base
      # @see Worker::Config
      class Build < Base

        #
        # API
        #

        # Build exit status
        # @return [Integer] 0 for success, 1 otherwise
        attr_reader :status

        # Output that was collected during build run
        # @return [String]
        attr_reader :log

        def initialize(payload)
          super
          observers << self
          @log = ''
          Travis::Worker.shell.on_output do |data|
            print data
            update(:log => data)
          end
        end

        def start
          notify(:start, :started_at => Time.now)
          update(:log => "Using worker: #{Travis::Worker.name}\n\n")
        end

        def update(data)
          notify(:update, data)
        end

        def finish
          notify(:finish, :log => log, :status => status, :finished_at => Time.now)
          Travis::Worker.shell.close if Travis::Worker.shell
        end

        #
        # Implementation
        #

        protected

        def on_update(data)
          log << data[:log] if data.key?(:log)
        end

        def perform
          if repository.build?
            @status = build! ? 0 : 1
            sleep(Travis::Worker.config.shell.buffer * 2) # TODO hrmmm ...
          else
            @status = 1
          end
        rescue
          @status = 1
          update(:log => "#{$!.class.name}: #{$!.message}\n#{$@.join("\n")}")
        ensure
          update(:log => "\nDone. Build script exited with: #{status}\n")
        end

        def build!
          sandboxed do
            chdir
            setup_env
            repository.checkout(build.commit)
            repository.install && run_scripts
          end
        end

        def setup_env
          exec "rvm use #{config.rvm || 'default'}"
          exec "export BUNDLE_GEMFILE=#{config.gemfile}" if config.gemfile
          Array(config.env).each { |env| exec "export #{env}" } if config.env
        end

        def run_scripts
          %w{before_script script after_script}.each do |type|
            script = config.send(type)
            puts "[jobs.build] Running #{type}"
            break false if script && !run_script(script, :timeout => type)
          end
          puts "[jobs.build] Done running scripts"
          true
        end

        def run_script(script, options = {})
          (script.is_a?(Array) ? script : script.split("\n")).each do |script|
            break false unless exec(script, options)
          end && true
        end

        def chdir(&block)
          exec "mkdir -p #{build_dir}; cd #{build_dir}", :echo => false
        end
      end # Build
    end # Job
  end # Worker
end # Travis
