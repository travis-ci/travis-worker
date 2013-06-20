require 'net/ssh'
require 'shellwords'
require 'travis/worker/utils/buffer'
require 'travis/support/logging'
require 'base64'

module Travis
  module Worker
    module Ssh
      # Encapsulates an SSH connection to a remote host.
      class Session
        include Logging

        class NoOutputReceivedError < StandardError
          attr_reader :minutes
          def initialize(minutes)
            super("No output has been received in the last #{minutes} minutes, this potentially indicates a stalled build or something wrong with the build itself.\n\nThe build has been terminated")
          end
        end

        log_header { "#{name}:shell:session" }

        attr_reader :name, :config, :ssh_session

        # Initialize a shell Session
        #
        # config - A hash containing the timeouts, shell buffer time and ssh connection information
        # block - An optional block of commands to be excuted within the session. If
        #         a block is provided then the session will be started, block evaluated,
        #         and then the session will be closed.
        def initialize(name, config)
          @name = name
          @config = Hashr.new(config)
        end

        # Connects to the remote host.
        #
        # Returns the Net::SSH::Shell
        def connect(silent = false)
          info "starting ssh session to #{config.host}:#{config.port} ..." unless silent
          options = { :port => config.port, :paranoid => false }
          options[:password] = config.password if config.password?
          options[:keys] = [config.private_key_path] if config.private_key_path?
          @ssh_session = Net::SSH.start(config.host, config.username, options)
          true
        end

        # Closes the Shell, flushes and resets the buffer
        def close
          Timeout::timeout(5) { ssh_session.close if open? }
        rescue
          warn "ssh connection could not be closed gracefully"
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

        # Checks is the current shell is open.
        #
        # Returns true if the shell has been setup and is open, otherwise false.
        def open?
          ssh_session && !ssh_session.closed?
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
        def exec(command)
          connect unless open?

          exit_code = nil

          ssh_session.open_channel do |channel|
            channel.request_pty do |channel, success|
              raise StandardError, "could not obtain pty" unless success

              channel.exec("/bin/bash --login -c #{Shellwords.escape(command)}") do |ch, success|
                unless success
                  raise StandardError, "FAILED: couldn't execute command (ssh.channel.exec)"
                end

                channel.on_data do |ch, data|
                  buffer << data
                end

                channel.on_extended_data do |ch, type, data|
                  buffer << data
                end

                channel.on_request("exit-status") do |ch, data|
                  exit_code = data.read_long
                end
              end
            end
          end

          if block_given?
            ssh_session.loop(0.5) do
              buffer_flush_exceeded?
              early_exit = yield
              # puts "!(early_exit || !!exit_code) : !(#{early_exit} || #{!!exit_code}) == #{!(early_exit || !!exit_code)}"
              !(early_exit || !!exit_code)
            end
          else
            ssh_session.loop(1)
          end

          exit_code
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

          def buffer_flush_exceeded?
            flushed_limit = Travis::Worker.config.limits.last_flushed

            if (Time.now.to_i - buffer.last_flushed) > (flushed_limit * 60)
              warn "Flushed limit exceeded: @flushed_limit = #{flushed_limit}, now = #{Time.now.to_i}"
              buffer.stop
              raise NoOutputReceivedError.new(flushed_limit.to_s)
            end
          end
      end
    end
  end
end
