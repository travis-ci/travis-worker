require "thor"

require "java"
require "hot_bunnies"
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

          publish(payload, "builds.jvmotp", self.options[:n].to_i)
        end


        desc "build_with_missing_repo", "Publish a sample Clojure build job that tries to clone a repo that does not exist"
        method_option :slug,   :default => "michaelklishin/urly8277"
        method_option :commit, :default => "d487ca890f6e7c358274a32f722506bd5568fdfc"
        method_option :branch, :default => "master"
        method_option :n,      :default => 1
        def build_with_missing_repo
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

          publish(payload, "builds.jvmotp", self.options[:n].to_i)
        end


        desc "build_clojure2", "Publish a sample Clojure build job"
        method_option :slug,   :default => "michaelklishin/monger"
        method_option :commit, :default => "a75e0dbd7c79f30b148b0e3c765550530e89a7cc"
        method_option :branch, :default => "master"
        method_option :n,      :default => 1
        def build_clojure2
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
              :script   => "lein multi test",
              :before_install => "lein plugin install lein-multi 1.1.0"
            }
          }

          publish(payload, "builds.jvmotp", self.options[:n].to_i)
        end



        desc "build_clojure_with_lein2", "Publish a sample Clojure build job that uses Leiningen 2"
        method_option :slug,   :default => "travis-ci/travis-ci-clojure-leiningen-2-example"
        method_option :commit, :default => "1583e820218a399e89db2362fe1c99f95c4a6a63"
        method_option :branch, :default => "master"
        method_option :n,      :default => 1
        def build_clojure_with_lein2
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
              :lein     => "lein2"
            }
          }

          publish(payload, "builds.jvmotp", self.options[:n].to_i)
        end


        desc "build_groovy", "Publish a sample Groovy build job"
        method_option :slug,   :default => "gradle/gradle"
        method_option :commit, :default => "c8c75360b859e9fab40dd0b6eb0cd8e925c2170c"
        method_option :branch, :default => "master"
        method_option :n,      :default => 1
        def build_groovy
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
              :language => "groovy"
            }
          }

          publish(payload, "builds.jvmotp", self.options[:n].to_i)
        end


        desc "build_java_with_maven", "Publish a sample Java build job that will use Maven"
        method_option :slug,   :default => "clojure/clojure"
        method_option :commit, :default => "7783f62afc5c113b1e013b8967acbdade58d0fb5"
        method_option :branch, :default => "master"
        method_option :n,      :default => 1
        def build_java_with_maven
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
              :language => "java"
            }
          }

          publish(payload, "builds.jvmotp", self.options[:n].to_i)
        end



        desc "build_java_with_ant", "Publish a sample Java build job that will use Ant"
        method_option :slug,   :default => "jruby/jruby"
        method_option :commit, :default => "90995615bc776d6d4b3ea25e2a45f7e8423e33a8"
        method_option :branch, :default => "jruby-1_6"
        method_option :n,      :default => 1
        def build_java_with_ant
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
              :language => "java",
              :script   => "ant test"
            }
          }

          publish(payload, "builds.jvmotp", self.options[:n].to_i)
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


        desc "build_python", "Publish a sample Python build job"
        method_option :slug,   :default => "dstufft/slumber"
        method_option :commit, :default => "8fb2a1a9c100e90c4586e8ca31d2122bfef2cfe8"
        method_option :branch, :default => "master"
        method_option :n,      :default => 1
        def build_python
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
              :language => "python",
              :python   => "2.7",
              :script   => "python setup.py test",
              :install  => "pip install -r requirements.txt && pip install -r requirements-test.txt"
            }
          }

          publish(payload, "builds.php", self.options[:n].to_i)
        end


        desc "build_haskell", "Publish a sample Haskell build job"
        method_option :slug,   :default => "travis-repos/TravisHSTest"
        method_option :commit, :default => "ca256b982dd8af09a66b72cf22be376c46b8edfb"
        method_option :branch, :default => "master"
        method_option :n,      :default => 1
        def build_haskell
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
              :language => "haskell"
            }
          }

          publish(payload, "builds.jvmotp", self.options[:n].to_i)
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
