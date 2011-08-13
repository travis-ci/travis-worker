require "thor"

require "amqp"
require "multi_json"
require 'travis/worker'

module Travis
  module Worker
    module Cli
      # These tasks are used for development and only for development.
      # They have many limitations and SHOULD NOT be considered good
      # programming style or examples for adding new commands to Travis Worker CLI.
      class Development < Thor
        namespace "travis:worker:dev"



        desc "receiver", "Start progress reports receiver tool"
        def receiver
          AMQP.start(:vhost => "travis") do |connection|
            ch       = AMQP::Channel.new(connection)
            ch.queue("reporting.progress", :auto_delete => true).subscribe do |metadata, payload|
              puts "[#{metadata.type}] #{payload}"
            end
          end
        end




        desc "build_ruby", "Publish a sample Ruby build job"
        method_option :slug,   :default => "ruby-amqp/amq-protocol"
        method_option :commit, :default => "e54c27a8d1c0f4df0fc9"
        method_option :branch, :default => "master"
        method_option :n,      :default => 1
        def build_ruby
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

          publish(payload, "builds", self.options[:n].to_i)
        end




        desc "build_clojure", "Publish a sample Clojure build job"
        method_option :slug,   :default => "michaelklishin/langohr"
        method_option :commit, :default => "e32b1daf33b691625129"
        method_option :branch, :default => "master"
        method_option :n,      :default => 1
        def build_clojure
          payload = {
            :repository => {
              :slug => self.options[:slug]
            },
            :build => {
              :id       => 1,
              :commit => self.options[:commit],
              :branch => self.options[:branch],
              :config => {
                :language => "Clojure"
              }
            }
          }
          puts payload.inspect

          publish(payload, "builds", self.options[:n].to_i)
        end





        desc "config", "Publish a sample config job"
        method_option :slug,   :default => "ruby-amqp/amq-protocol"
        method_option :commit, :default => "e54c27a8d1c0f4df0fc9"
        method_option :branch, :default => "master"
        method_option :n,      :default => 1
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

          publish(payload, "config", self.options[:n].to_i)
        end



        protected

        def publish(payload, routing_key, n = 1)
          AMQP.start(:vhost => "travis") do |connection|
            exchange = AMQP.channel.default_exchange
            n.times { exchange.publish(MultiJson.encode(payload), :routing_key => routing_key) }

            EventMachine.add_timer(1) { AMQP.connection.disconnect { puts("Disconnecting..."); EventMachine.stop } }
          end
        end

      end # Development
    end
  end # Worker
end # Travis
