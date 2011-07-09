require "thor"

require "amqp"
require "multi_json"
require 'travis/worker'

module Travis
  module Worker
    module Cli
      class Development < Thor
        namespace "travis:worker:dev"


        desc "build", "Publish a sample build job"
        method_option :slug,   :default => "ruby-amqp/amq-protocol"
        method_option :commit, :default => "e54c27a8d1c0f4df0fc9"
        method_option :branch, :default => "master"
        def build
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

          publish(payload, "builds")
        end





        desc "config", "Publish a sample config job"
        method_option :slug,   :default => "ruby-amqp/amq-protocol"
        method_option :commit, :default => "e54c27a8d1c0f4df0fc9"
        method_option :branch, :default => "master"
        def config
          payload = {
            :repository => {
              :slug => self.options[:slug]
            },
            :build => {
              :id     => 1,
              :commit => self.options[:commit],
              :branch => self.options[:branch]
            }
          }
          puts payload.inspect

          publish(payload, "builds")
        end



        protected

        def publish(payload, routing_key)
          AMQP.start(:vhost => "travis") do |connection|
            AMQP.channel.default_exchange.publish(MultiJson.encode(payload), :routing_key => routing_key) do
              AMQP.connection.disconnect { puts("Disconnecting..."); EventMachine.stop }
            end
          end
        end

      end # Development
    end
  end # Worker
end # Travis
