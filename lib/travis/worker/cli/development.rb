require "thor"

require "amqp"
require "travis/worker"

require "multi_json"

module Travis
  module Worker
    module Development
      class Job < Thor
        desc "publish", "Publish a sample job payload"
        method_option :slug,   :default => "ruby-amqp/amq-protocol"
        method_option :commit, :default => "e54c27a8d1c0f4df0fc9"
        method_option :branch, :default => "master"
        def publish
          payload = {
            :repository => {
              :slug => self.options[:slug]
            },
            :build => {
              :id     => 1,
              :commit => self.options[:commit],
              :branch => self.options[:branch],
              :config => {
                :rvm          => "1.8.7",
                :script       => "bundle exec rspec spec",
                :bundler_args => "--without development"
              }
            }
          }
          puts payload.inspect

          AMQP.start(:vhost => "travis") do |connection|
            AMQP.channel.default_exchange.publish(MultiJson.encode(payload), :routing_key => "builds") do
              AMQP.connection.disconnect { puts("Disconnecting..."); EventMachine.stop }
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
