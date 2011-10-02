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
        method_option :immute, :aliases => '-i', :type => :boolean, :default => false, :desc => 'Make all disks in the current vagrant environment immutable'
        method_option :snapshot, :aliases => '-s', :type => :boolean, :default => true, :desc => 'Take online snapshots of all vms'
        method_option :reset, :aliases => '-r', :type => :boolean, :default => false, :desc => 'Force reset on virtualbox settings and boxes'
        def update
          vbox.reset

          # download
          add_box
          exit unless up
          immute
        end

        desc 'immute', 'Make all disks in the current vagrant environment immutable'
        def immute
          modify_disks('immutable')
        end

        desc 'unimmute', 'Make all disks in the current vagrant environment immutable'
        def unimmute
          modify_disks('normal')
        end

        desc 'snapshot', 'Take online snapshots of all vms'
        def snapshot
          up
          pause
          vms.each { |name, uuid| take_snapshot(name, uuid) }
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

          def up
            run "vagrant up --provision=true"
          end

          def pause
            vms.each { |name, uuid| pause_vm(name) }
          end

          def halt
            run 'vagrant halt'
          end

          def remove_box(name)
            run "vagrant box remove #{name}"
          end

          def destroy(name)
            run "vagrant destroy #{name}"
          end

          def vms
            `VBoxManage list vms`.split("\n").map do |vm|
              vm =~ /"(.*)" {(.*)}/
              [$1, $2]
            end
          end

          def pause_vm(name)
            run "VBoxManage controlvm #{name} pause"
          end

          def modify_disks(type)
            halt
            vms.each { |name, uuid| modify_disk(name, uuid, type) }
          end

          def modify_disk(name, uuid, type)
            run <<-sh
              VBoxManage storageattach #{uuid} --storagectl "SATA Controller" --port 0 --device 0 --medium none
              VBoxManage modifyhd ~/VirtualBox\\ VMs/#{name}/box-disk1.vmdk --type #{type}
              VBoxManage storageattach #{uuid} --storagectl "SATA Controller" --port 0 --device 0 --medium ~/VirtualBox\\ VMs/#{name}/box-disk1.vmdk --type hdd
            sh
          end

          def take_snapshot(name, uuid)
            run "VBoxManage snapshot '#{name}' take 'initial snapshot'"
          end
      end
    end
  end
end
