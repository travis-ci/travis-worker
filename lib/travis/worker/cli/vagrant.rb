require 'thor'
require 'yaml'
require 'json'
require 'travis/worker'


module Travis
  module Worker
    module Cli
      class Vagrant < Thor
        namespace "travis:worker:vagrant"

        include Cli

        desc 'rebuild', 'Rebuild all worker vms'
        def rebuild
          vbox.reset

          download unless File.exists?(BASE_BOX)


          run 'wget http://files.vagrantup.com/lucid32.box' unless File.exists?('lucid32.box')
          run 'vagrant box add lucid32 lucid32.box'
          wait 5
          exit unless run 'vagrant up base'

          vms = JSON.parse(File.read('.vagrant'))
          uuid = vms['active']['base'] || raise("could not find base uuid in #{vms.inspect}")

          run 'rm -rf base.box'
          run "vagrant package --base #{uuid}"
          run 'mv package.box base.box'

          run 'vagrant box add base base.box'
          wait 5
          1.upto(config.count) do |num|
            run "vagrant up worker-#{num}"
          end
        end

        protected

          def vbox
            @vbox ||= Vbox.new
          end

          def config
            @config ||= Travis::Worker::Vagrant::Config.new(YAML.load_file('.vms.yml'))
          end
      end
    end
  end
end
