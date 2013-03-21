require 'sshjr'
require 'thread'

module Travis
  module Worker
    module Ssh
      module Connector
        class SSHJr
          def initialize(config)
            @config = config
          end

          def connect
            options = { :port => @config.port }
            options[:password] = @config.password if @config.password?
            options[:private_key_paths] = [@config.private_key_path] if @config.private_key_path?
            @client = SSHJr::Client.start(@config.host, @config.username, options)
          end

          def close
            @client.close if open?
          end

          def exec(command, buffer)
            connect unless open?

            exit_code = nil

            session = @client.start_session
            session.allocate_default_pty
            command = session.exec("/bin/bash --login -c #{Shellwords.escape(command)}")
            output = command.input_stream.to_io # In Java, input is output, apparently.
            error = command.error_stream.to_io

            data_threads = []
            data_mutex = Mutex.new

            data_threads << Thread.new(output, buffer) do |output, buffer|
              output.each_char do |char|
                data_mutex.synchronize do
                  buffer << char
                end
              end
            end

            data_threads << Thread.new(error, buffer) do |error, buffer|
              error.each_char do |char|
                data_mutex.synchronize do
                  buffer << char
                end
              end
            end

            loop do
              if block_given?
                early_exit = yield
                exit_code = command.exit_status
                if (early_exit || !!exit_code)
                  command.close
                  session.close
                end
                sleep(0.5)
              else
                sleep(1)
                exit_code = command.exit_status
                if exit_code
                  command.close
                  session.close
                  break
                end
              end
            end

            data_threads.map(&:exit)

            exit_code
          end

          private

          def open?
            @client && @client.connected?
          end
        end
      end
    end
  end
end

