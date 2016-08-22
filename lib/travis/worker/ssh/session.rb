require 'shellwords'
require 'travis/worker/utils/buffer'
require 'travis/worker/utils/hard_timeout'
require 'travis/worker/ssh/connector/net_ssh'
require 'travis/support/logging'
require 'base64'
require 'hashr'

module Travis
  module Worker
    module Ssh
      # Encapsulates an SSH connection to a remote host.
      class Session
        include Logging

        class NoOutputReceivedError < StandardError
          def initialize(seconds)
            super("No output has been received in the last #{(seconds / 60).to_i} minutes, this potentially indicates a stalled build or something wrong with the build itself.\nCheck the details on how to adjust your build configuration on: https://docs.travis-ci.com/user/common-build-problems/#Build-times-out-because-no-output-was-received\n\nThe build has been terminated")
          end
        end

        log_header { "#{name}:shell:session" }

        attr_reader :name, :config
        attr_accessor :log_silence_timeout

        # Initialize a shell Session
        #
        # config - A hash containing the timeouts, shell buffer time and ssh connection information
        # block - An optional block of commands to be excuted within the session. If
        #         a block is provided then the session will be started, block evaluated,
        #         and then the session will be closed.
        def initialize(name, config)
          @name = name
          @config = Hashr.new(config)
          @connector = Connector::NetSSH.new(@config)
        end

        # Connects to the remote host.
        #
        # Returns the Net::SSH::Shell
        def connect(silent = false)
          info "starting ssh session to #{config.host}:#{config.port} ..." unless silent
          Travis::Worker::Utils::HardTimeout.timeout(15) do
            @connector.connect
          end
          if @config.platform == :osx
            info "unlocking keychain" unless silent
            exec("security unlock-keychain -p #{config.keychain_password}")
          end
          true
        rescue Timeout::Error
          warn "Timed out attempting to open SSH connection"
          raise
        end

        # Closes the Shell, flushes and resets the buffer
        def close
          Timeout.timeout(3) { @connector.close }
          true
        rescue
          warn "ssh connection could not be closed gracefully"
          Metriks.meter('worker.vm.ssh.could_not_close').mark
          false
        ensure
          buffer.stop
          @buffer = nil
        end

        # Allows you to set a callback when output is received from the ssh shell.
        #
        # on_output - The block to be called.
        def on_output(&on_output)
          uuid = Travis.uuid
          @on_output = lambda do |*args, &block|
            Travis.uuid = uuid
            on_output.call(*args, &block)
          end
        end

        # This is where the real SSH shell work is done. The command is run along with
        # callbacks setup for when data is returned. The exit status is also captured
        # when the command has finished running.
        #
        # command - The command to be executed.
        # block   - A block which will be called when output or error output is received
        #           from the shell command.
        #
        # Returns the exit status (0 or 1)
        def exec(command, &block)
          if block
            @connector.exec(command, buffer) do
              check_log_silence
              block.call
            end
          else
            @connector.exec(command, buffer)
          end
        end

        def upload_file(path_and_name, content)
          encoded = Base64.encode64(content).gsub("\n", "")
          command = "(echo #{encoded} | #{decode_base64_command}) >> #{path_and_name}"
          exec(command)
        end

        protected

          def decode_base64_command
            case config.platform
            when :osx
              'base64 -D'
            else
              'base64 -d'
            end
          end

          # Internal: Sets up and returns a buffer to use for the entire ssh session when code
          # is executed.
          def buffer
            @buffer ||= Utils::Buffer.new(config.buffer, log_header: name) do |string|
              @on_output.call(string, :header => log_header) if @on_output
            end
          end

          def check_log_silence
            elapsed = Time.now.to_i - buffer.last_flushed
            if elapsed > log_silence_timeout
              warn "Flushed limit exceeded: timeout = #{log_silence_timeout} sec, now = #{Time.now.to_i}"
              buffer.stop
              raise NoOutputReceivedError.new(log_silence_timeout)
            end
          end
      end
    end
  end
end
