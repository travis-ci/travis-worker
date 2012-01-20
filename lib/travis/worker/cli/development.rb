require "thor"

require "java"
require "hot_bunnies"
require "multi_json"
require 'travis/worker'

module Travis
  class Worker
    module Cli
      # These tasks are used for development and only for development.
      # They have many limitations and SHOULD NOT be considered good
      # programming style or examples for adding new commands to Travis Worker CLI.
      class Development < Thor
        namespace "travis:worker:dev"



        desc "build_ruby", "Publish a sample Ruby build job"
        method_option :slug,   :default => "ruby-amqp/amq-protocol"
        method_option :commit, :default => "bc0a938c19d18e2e6973debe2b5bc4a1bd8ea469"
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
              :branch => self.options[:branch]
            },
            :config => {
              :language     => "ruby",
              :rvm          => "1.8.7",
              :script       => "bundle exec rspec spec",
              :bundler_args => "--without development"
            }
          }

          publish(payload, "builds.common", self.options[:n].to_i)
        end



        desc "test_log_trimming", "Run a sample Ruby build that goes way over allowed build log output length"
        method_option :slug,   :default => "travis-repos/noise_maker"
        method_option :commit, :default => "677e2c2b34b46cee9e0607506b7d7ad67898138a"
        method_option :branch, :default => "master"
        method_option :n,      :default => 1
        def test_log_trimming
          payload = {
            :repository => {
              :slug => self.options[:slug]
            },
            :build => {
              :id     => 1,
              :commit => self.options[:commit],
              :branch => self.options[:branch]
            },
            :config => {
              :language     => "ruby",
              :rvm          => "1.9.3",
              :script       => "bundle exec rspec -c spec",
              :bundler_args => "--without development"
            }
          }

          publish(payload, "builds.common", self.options[:n].to_i)
        end




        desc "build_clojure", "Publish a sample Clojure build job"
        method_option :slug,   :default => "michaelklishin/urly"
        method_option :commit, :default => "d487ca890f6e7c358274a32f722506bd5568fdfc"
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
              :branch => self.options[:branch]
            },
            :config => {
              :language => "clojure",
              :script   => "lein javac, test"
            }
          }

          publish(payload, "builds.common", self.options[:n].to_i)
        end



        desc "build_node", "Publish a sample Node build job"
        method_option :slug,   :default => "mmalecki/node-functions"
        method_option :commit, :default => "103362faa086fb8646bd67343d363cf3f1baafeb"
        method_option :branch, :default => "master"
        method_option :n,      :default => 1
        def build_node
          payload = {
            :repository => {
              :slug => self.options[:slug]
            },
            :build => {
              :id       => 1,
              :commit => self.options[:commit],
              :branch => self.options[:branch]
            },
            :config => {
              :language => "node_js",
              :node_js => "0.4"
            }
          }

          publish(payload, "builds.node_js", self.options[:n].to_i)
        end



        protected

        def publish(payload, routing_key, n = 1)
          puts payload.inspect

          connection = HotBunnies.connect(:vhost => "travisci.development", :username => "travisci_worker", :password => "travisci_worker_password")
          channel    = connection.create_channel
          exchange   = channel.default_exchange

          n.times { exchange.publish(MultiJson.encode(payload), :routing_key => routing_key) }

          sleep(1.0)
          channel.close
          connection.close

          java.lang.System.exit(0)
        end

      end # Development
    end
  end # Worker
end # Travis
