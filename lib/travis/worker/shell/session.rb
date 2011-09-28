require 'net/ssh'
require 'net/ssh/shell'
require 'fileutils'

module Travis
  module Worker
    module Shell

      class Session
        autoload :Helpers, 'travis/worker/shell/helpers'

        include Shell::Helpers


        # Public: VirtualBox VM instance used by the session
        attr_reader :vm

        # VirtualBox environment ssh configuration
        attr_reader :config

        # Net::SSH session
        # @return [Net::SSH::Connection::Session]
        attr_reader :shell

        # VBoxManage log file path
        # @return [String]
        attr_reader :log

        def initialize(vm, config)
          @vm     = vm
          @config = config
          @shell  = start_shell

          yield(self) if block_given?
        end

        def execute(command, options = {})
          command = timetrap(command, :timeout => timeout(options)) if options[:timeout]
          command = echoize(command) unless options[:echo] == false

          exec(command) { |p, data| buffer << data } == 0
        end

        def evaluate(command)
          result = ''
          status = exec(command) { |p, data| result << data }
          raise("command #{command} failed: #{result}") unless status == 0
          result
        end

        def close
          shell.wait!
          shell.close!
          buffer.flush
        end

        def on_output(&block)
          @on_output = block
        end


        protected

          def start_shell
            puts "starting ssh session to #{config.host}:#{vm.ssh.port} ..."
            Net::SSH.start(config.host, config.username, :port => vm.ssh.port, :keys => [config.private_key_path]).shell.tap do
              puts 'done.'
            end
          end

          def buffer
            @buffer ||= Buffer.new do |string|
              @on_output.call(string) if @on_output
            end
          end

          def exec(command, &on_output)
            status = nil
            shell.execute(command) do |process|
              process.on_output(&on_output)
              process.on_error_output(&on_output)
              process.on_finish { |p| status = p.exit_status }
            end
            shell.session.loop { status.nil? }
            status
          end


        private

          def timeout(options)
            if options[:timeout].is_a?(Numeric) ?
              options[:timeout]
            else
              timeout = options[:timeout] || :default
              Travis::Worker.config.timeouts[timeout]
            end
          end
      end

    end
  end
end
