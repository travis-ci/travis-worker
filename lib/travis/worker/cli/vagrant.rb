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

        desc 'update', 'Update the worker vms from a base box'
        method_option :env
        method_option :force, :aliases => '-f', :type => :boolean, :default => false, :desc => 'Force reset on virtualbox settings and boxes'
        def update
          vbox.reset

          # download
          add_box
          exit unless up
          # immute_disk env
        end

        # desc 'remove', 'Remove the worker boxes'
        # def remove
        #   1.upto(config.count) do |num|
        #     destroy "worker-#{num}"
        #     remove_box "worker-#{num}"
        #   end
        # end

        protected

          def vbox
            @vbox ||= Vbox.new('', options)
          end

          def config
            self.class.config
          end

          def env
            options['env'] || Travis::Worker.config.env
          end

          def base
            "boxes/#{env}.box"
          end

          # def download
          #   run "wget http://files.vagrantup.com/#{from}.box" unless File.exists?("#{from}.box")
          # end

          # def immute_disk(name)
          #   run "VBoxManage modifyhd ~/.vagrant.d/boxes/#{name}/box-disk1.vmdk --type immutable"
          # end

          def add_box
            run "vagrant box add #{env} #{base}"
          end

          def up
            run "vagrant up --provision=true"
          end

          def remove_box(name)
            run "vagrant box remove #{name}"
          end

          def destroy(name)
            run "vagrant destroy #{name}"
          end

          # def uuid
          #   vms = JSON.parse(File.read('.vagrant'))
          #   vms['active']['base'] || raise("could not find base uuid in #{vms.inspect}")
          # end
      end
    end
  end
end
