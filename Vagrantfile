$: << 'lib'
require 'travis/worker'

Vagrant::Config.run do |config|
  1.upto(ENV.fetch("TRAVIS_VAGRANT_WORKERS", Travis::Worker.config.workers).to_i) do |num|
    config.vm.define :"worker-#{num}" do |config|
      config.vm.box = ENV.fetch("VAGRANT_BASE", "worker-#{num}")
      config.vm.provision :chef_solo do |chef|
        chef.cookbooks_path = "vendor/cookbooks/vagrant_base"
        chef.log_level      = :debug

        config.vm.customize do |vm|
          vm.memory_size = ENV.fetch("VAGRANT_VM_MEMORY_SIZE", 1536)
        end

        chef.add_recipe "apt"
        chef.add_recipe "build-essential"
        chef.add_recipe "networking_basic"
        chef.add_recipe "openssl"
        # libyaml MUST be installed before rubies. MK.
        chef.add_recipe "libyaml"

        # for debugging. MK.
        chef.add_recipe "emacs"
        chef.add_recipe "vim"

        chef.add_recipe "git"
        chef.add_recipe "java::openjdk"

        chef.add_recipe "rvm"
        chef.add_recipe "rvm::multi"

        chef.add_recipe "travis_build_environment"

        chef.add_recipe "memcached"
        chef.add_recipe "rabbitmq"

        chef.add_recipe "sqlite"
        chef.add_recipe "postgresql::client"
        chef.add_recipe "postgresql::server"
        chef.add_recipe "redis"
        chef.add_recipe "mysql::client"
        chef.add_recipe "mysql::server"
        chef.add_recipe "mongodb"

        chef.add_recipe "imagemagick"

        # You may also specify custom JSON attributes:
        chef.json.merge!(
          :rvm => {
            :rubies       => %w(ruby-1.8.6 ruby-1.8.7 ruby-1.8.7-p174 ruby-1.8.7-p249 ruby-1.9.2 1.9.1-p378 jruby rbx rbx-2.0.0pre ree ruby-head),
            :default_ruby => "ruby-1.8.7",
            :default_gems => %w(bundler rake chef),
            :aliases      => {
              "rbx-2.0.0pre" => "rbx-2.0",
              "1.9.1-p378"   => "1.9.1"
            }
          },
          :mysql => {
            :server_root_password => ""
          }
        )
      end # config.vm.provision
    end # config.vm.define
  end # 1.upto
end # Config.run
