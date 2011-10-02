require "travis/worker/job/base"

module Travis
  module Worker

    module Job
      # Build job implementation that uses the following workflow:
      #
      # * Clones/fetches the repository from {https://github.com GitHub}
      # * Installs dependencies
      # * Switches to the default or specified language implementation
      # * Runs one or more build scripts
      #
      # @see Base
      # @see Worker::Config
      class Build < Base

        # Build exit status
        # @return [Integer] 0 for success, 1 otherwise
        attr_reader :status

        # Output that was collected during build run
        # @return [String]
        attr_reader :log

        def initialize(payload, virtual_machine)
          super
          @log = ''
          repository.shell = shell
          setup_shell_logging
        end

        def start
          notify(:start, :started_at => Time.now, :queue => Travis::Worker.config.queue)
          update(:log => "Using worker: #{Travis::Worker.name}\n\n")
        end

        def update(data)
          log << data[:log] if data.key?(:log)
          notify(:update, data)
        end

        def finish
          notify(:finish, :log => log, :status => status, :finished_at => Time.now)
          shell.close if shell.open?
        end


        protected

          def shell
            @shell ||= begin
              connection_details = Hashr.new({
                :host => '127.0.0.1',
                :port => virtual_machine.ssh_port,
                :username => 'vagrant',
                :private_key_path => File.expand_path("keys/vagrant")
              })
              Travis::Worker::Shell::Session.new(connection_details)
            end
          end

          def setup_shell_logging
            shell.on_output do |data|
              print data
              update(:log => data)
            end
          end

          def perform
            @status = build! ? 0 : 1
            sleep(2) # TODO hrmmm ...
          rescue
            @status = 1
            update(:log => "#{$!.class.name}: #{$!.message}\n#{$@.join("\n")}")
          ensure
            update(:log => "\nDone. Build script exited with: #{status}\n")
          end

          def build!
            virtual_machine.sandboxed do
              shell.connect
              create_builds_directory && checkout_repository && run_build
              shell.close
            end
          end

          def create_builds_directory
            shell.execute("mkdir -p #{self.class.base_dir}; cd #{self.class.base_dir}", :echo => false)
          end

          def run_build
            builder = Travis::Worker::Builder.create(build.config)
            puts "Using #{builder.inspect}"
            commands = builder::Commands.new(build.config, shell)
            commands.run
          end

          def checkout_repository
            repository.checkout(build.commit)
          end
      end

    end
  end
end
