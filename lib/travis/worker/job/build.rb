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
          notify(:start, :started_at => Time.now, :queue => Travis::Worker.config.queue)
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
            @status = build! ? 0 : 1
            sleep(Travis::Worker.config.shell.buffer * 2) # TODO hrmmm ...
          rescue
            @status = 1
            update(:log => "#{$!.class.name}: #{$!.message}\n#{$@.join("\n")}")
          ensure
            update(:log => "\nDone. Build script exited with: #{status}\n")
          end

          def build!
            sandboxed do
              create_builds_directory && checkout_repository && run_build
            end
          end

          def create_builds_directory
            exec "mkdir -p #{self.class.base_dir}; cd #{self.class.base_dir}", :echo => false
          end

          def run_build
            builder = Travis::Worker::Builders.builder_for(build.config)
            puts "Using #{builder.inspect}"
            commands = builder::Commands.new(build.config)
            commands.run
          end

          def checkout_repository
            repository.checkout(build.commit)
          end
      end # Build
    end # Job
  end # Worker
end # Travis
