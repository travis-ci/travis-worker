require 'thor'
require 'yaml'
require 'json'
require 'travis/worker'

module Travis
  class Worker
    module Cli
      class Vagrant < Thor
        namespace "travis:vms"

        include Cli

        desc 'update [BOX]', 'Update the worker vms from a base box (BOX defaults to Travis::Worker.config.env)'
        method_option :immute,   :aliases => '-i', :type => :boolean, :default => false, :desc => 'Make all disks in the current vagrant environment immutable'
        method_option :snapshot, :aliases => '-s', :type => :boolean, :default => true,  :desc => 'Take online snapshots of all vms'
        method_option :reset,    :aliases => '-r', :type => :boolean, :default => false, :desc => 'Force reset on virtualbox settings and boxes'
        method_option :download, :aliases => '-d', :type => :string,  :default => false, :desc => 'Copy/download the base box from the given path, storage or URL (will use file.travis.org if -d is given without a string)'

        def update(box = Travis::Worker.config.env)
          self.box = box

          vbox.reset if options[:reset]
          download if download?
          add_box
          exit unless up
          halt
        rescue => e
          puts e.message
        end

        protected

          attr_accessor :box

          def vbox
            @vbox ||= Vbox.new('', options)
          end

          def config
            self.class.config
          end

          def base_box
            "boxes/travis-#{box}.box"
          end

          def download?
            !!options[:download] || !File.exists?(base_box)
          end

          def download
            download_failed! unless run(download_command)
          end

          def download_command
            source =~ /^http:/ ? "wget #{source} -P boxes" : "cp #{source} boxes"
          end

          def download_failed!
            raise "The download command #{download_command} failed, terminating ..."
          end

          def source
            case options[:download]
            when 'download', NilClass
              "http://files.travis-ci.org/boxes/provisioned/travis-#{box}.box"
            else
              options[:download]
            end
          end

          def add_box
            run "vagrant box add travis-#{box} #{base_box}"
          end

          def up
            run "vagrant up"
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
      end
    end
  end
end
