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
            @client = ::SSHJr::Client.start(@config.host, @config.username, options)
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

