module Travis
  module Worker
    module Ssh
      module Connector
        class SSHJr
          def initialize(config)
            @config = config
          end

          def connect
            options = { :port => config.port }
            options[:password] = config.password if config.password?
            options[:private_key_paths] = [config.private_key_path] if config.private_key_path?
            @session = SSHJr::Client.start(config.host, config.username, options)
          end

          def close
            @session.close if open?
          end

          def exec(command, buffer)
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

          private

          def open?
            @session && @session.connected?
          end
        end
      end
    end
  end
end

