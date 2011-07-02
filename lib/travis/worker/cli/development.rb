require "thor"

require "amqp"
require "travis/worker"

module Travis
  module Worker
    module Development
      class Job < Thor
        desc "publish", "Publish a sample job payload"
        method_option :slug,   :default => "ruby-amqp/amq-protocol"
        method_option :commit, :default => "455e5f51605"
        method_option :branch, :default => "master"
        def publish
          AMQP.start(:vhost => "travis") do |connection|
            AMQP.channel.default_exchange.publish("Sample payload", :routing_key => "builds") do
              AMQP.connection.disconnect { EventMachine.stop }
            end
          end
        end
      end



      class Config < Thor
        desc "publish", "Publish a sample configuration payload"
        method_option :slug, :default => "ruby-amqp/amq-protocol"
        def publish
          puts "Publishing..."
        end
      end
    end # Development
  end # Worker
end # Travis
