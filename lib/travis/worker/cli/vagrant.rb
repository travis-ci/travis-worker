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
        method_option :from, :default => 'lucid32'
        def rebuild
          vbox.reset

          download unless File.exists?(BASE_BOX)
          add_box options['from']
          exit unless up 'base'
          package 'base'

          add_box 'base'
          up
        end

        protected

          def vbox
            @vbox ||= Vbox.new
          end

          def config
            @config ||= Travis::Worker::Vagrant::Config.new(YAML.load_file('.vms.yml'))
          end

          def download
            run 'wget http://files.vagrantup.com/lucid32.box' unless File.exists?('lucid32.box')
          end

          def add_box(name)
            run "vagrant box add #{name} #{name}.box"
          end

          def up(name)
            run "vagrant up #{name}"
          end

          def package(name)
            run "rm -rf #{name}.box"
            run "vagrant package --base #{uuid}"
            run "mv package.box #{name}.box"
          end

          def uuid
            vms = JSON.parse(File.read('.vagrant'))
            vms['active']['base'] || raise("could not find base uuid in #{vms.inspect}")
          end

      end
    end
  end
end
