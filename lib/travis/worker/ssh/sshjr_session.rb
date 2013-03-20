require 'sshjr'
require 'shellwords'
req

module Travis
  module Worker
    module Ssh
      class SSHJrSession
        include Logging

        class NoOutputReceivedError < StandardError
          attr_reader :minutes
          def initialize(minutes)
            super("No output has been received in the last #{minutes} minutes, this potentially indicates a stalled build or something wrong with the build itself.\n\nThe build has been terminated")
          end
        end

        log_header { "#{name}:shell:sshjr_session" }

        attr_reader :name, :config, :ssh_session

        # Initialize a shell Session
        #
        # config - A hash containing the timeouts, shell buffer time and ssh
        #          connection information.
        def initialize(name, config)
          @name = name
          @config = Hashr.new(config)
        end

        # Connects to the remote host
        def connect(silent = false)
          info "starting ssh session to #{config.host}:#{config.port} ..." unless silent
          options = { :port => config.port }
          options[:password] = config.password if config.password?
          options[:private_key_paths] = [config.private_key_path] if config.private_key_path?
          @ssh_session = SSHJr::Client.start(config.host, config.username, options)
          true
        end

        # Closes the Shell, flushes and resets the buffer
        def close
          Timeout.timeout(5) { ssh_session.close if open? }
        rescue
          warn "ssh connection could not be closed gracefully"
        ensure
          buffer.stop
          @buffer = nil
        end

        # Allows you to set a callback when output is received from the SSH
        # shell
        def on_output(&on_output)
          uuid = Travis.uuid
          @on_output = lambda do |*args, &block|
            Travis.uuid = uuid
            on_output.call(*args, &block)
          end
        end

        # Checks if the current shell is open.
        #
        # Returns true if the shell has been setup and is open, false
        # otherwise.
        def open?
          ssh_session && ssh_session.connected?
        end

        # This is where the real SSH shell work is done. The command is run
        # along with callbacks setup for when data is returned. The exit status
        # is also captured when the command has finished running.
        #
        # command - The command to be executed
        # block   - A block which will be called regularly while we are still
        #           connected. If this block returns true, the session will be
        #           closed.
        #
        # Returns the exit status.
        def exec(command)
          connect unless open?

          exit_code = nil

          session = ssh_session.start_session
          session.allocate_default_pty
          command = session.exec("/bin/bash --login -c #{Shellwords.escape(command)}")
          output = command.output_stream
          error = command.error_stream

          output.each_byte do |byte|
            buffer << byte
          end

          error.each_byte do |byte|
            buffer << byte
          end

          loop do
            if block_given?
              buffer_flush_exceeded?
              early_exit = yield
              exit_code = command.exit_status
              if (early_exit || !!exit_code)
                command.close
                session.close
              end
              sleep(0.5)
            else
              sleep(1)
            end
          end

          exit_code
        end

        def upload_file(path_and_name, content)
          encoded = Base64.encode64(content).gsub("\n", "")
          command = "(echo #{encoded} | base64 --decode) >> #{path_and_name}"
          exec(command)
        end

        protected

        def buffer
          @buffer ||= Utils::Buffer.new(config.buffer, log_header: name) do |string|
            @on_output.call(string, header: log_header) if @on_output
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

