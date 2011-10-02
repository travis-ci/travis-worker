require 'thor'
require 'yaml'
require 'json'
require 'travis/worker'

module Travis
  module Worker
    module Cli
      class Vagrant < Thor
        namespace "travis:vms"

        include Cli

        desc 'update', 'Update the worker vms from a base box'
        method_option :env
        method_option :immute,  :aliases => '-i', :type => :boolean, :default => true, :desc => 'Make all disks in the current vagrant environment immutable'
        method_option :reset,  :aliases => '-r', :type => :boolean, :default => false, :desc => 'Force reset on virtualbox settings and boxes'
        def update
          vbox.reset

          # download
          add_box
          exit unless up
          immute
        end

        desc 'immute', "Make all disks in the current vagrant environment immutable"
        def immute
          halt
          uuids.each do |name, uuid|
            immute_disk(name, uuid)
          end
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

          def add_box
            run "vagrant box add #{env} #{base}"
          end

          def halt
            run 'vagrant halt'
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

          def uuid
            vms = JSON.parse(File.read('.vagrant'))
            vms['active']['base'] || raise("could not find base uuid in #{vms.inspect}")
          end

          def uuids
            # "travis-worker_1317520507" {0ea36f25-89a2-4a79-8e6a-d6f6a4450b8f}
            # "travis-worker_1317520537" {b567d985-2c8a-4f8f-bcd3-be2d4b60e764}
            `VBoxManage list vms`.split("\n").map do |vm|
              vm =~ /"(.*)" {(.*)}/
              [$1, $2]
            end
          end

          def immute_disk(name, uuid)
            run <<-sh
              VBoxManage storageattach #{uuid} --storagectl "SATA Controller" --port 0 --device 0 --medium none
              VBoxManage modifyhd ~/VirtualBox\\ VMs/#{name}/box-disk1.vmdk --type immutable
              VBoxManage storageattach #{uuid} --storagectl "SATA Controller" --port 0 --device 0 --medium ~/VirtualBox\\ VMs/#{name}/box-disk1.vmdk --type hdd
            sh
          end
      end
    end
  end
end
