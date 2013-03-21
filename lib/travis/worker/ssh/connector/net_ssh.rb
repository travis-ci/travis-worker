module Travis
  module Worker
    module Ssh
      module Connector
        class NetSSH
          def initialize(config)
            @config = config
          end

          def connect
            options = { port: config.port, paranoid: false }
            options[:password] = config.password if config.password?
            options[:keys] = [config.private_key_path] if config.private_key_path?
            @session = Net::SSH.start(config.host, config.username, options)
          end

          def close
            @session.close if open?
          end

          def exec(command, buffer)
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
                early_exit = yield
                !(early_exit || !!exit_code)
              end
            else
              ssh_session.loop(1)
            end

            exit_code
          end

          private

          def open?
            @session && !@session.closed?
          end
        end
      end
    end
  end
end
