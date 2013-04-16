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
            @client = ::SSHJr::Client.new
            @client.connect(@config.host, @config.port)
            if @config.private_key_path?
              @client.authenticate(::SSHJr::Auth::PublicKey.new(@config.username, @config.private_key_path, @config.password))
            elsif @config.password?
              @client.authenticate(::SSHJr::Auth::Password.new(@config.username, @config.password))
            else
              raise ArgumentError, 'No valid authentication method specified'
            end
          end

          def close
            @client.close if open?
          end

          def exec(command, buffer, &block)
            connect unless open?

            command = @client.exec_with_pty("/bin/bash --login -c #{Shellwords.escape(command)}")
            command.on_output do |str|
              buffer << str
            end

            command.process(&block)
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

