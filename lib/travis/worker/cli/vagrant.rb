require 'thor'
require 'yaml'
require 'json'
require 'travis/worker'
require 'vagrant'

module Travis
  class Worker
    module Cli
      class Vagrant < Thor
        namespace "travis:vms"

        include Cli

        desc 'update [BOX]', 'Update the worker vms from a base box (BOX defaults to Travis::Worker.config.env)'
        method_option :reset,    :aliases => '-r', :type => :boolean, :default => false, :desc => 'Force reset on virtualbox settings and boxes'
        method_option :download, :aliases => '-d', :type => :string,  :default => false, :desc => 'Copy/download the base box from the given path, storage or URL (will use file.travis.org if -d is given without a string)'

        def update(box = Travis::Worker.config.env)
          self.box = box

          vbox.reset if options[:reset]
          download_box if download?
          add_box
          exit unless up
          halt
        rescue => e
          puts e.message
        end

        desc 'download [BOX]', 'Download the box image for a base box (BOX defaults to Travis::Worker.config.env)'
        method_option :download, :aliases => '-d', :type => :string,  :default => false, :desc => 'Copy/download the base box from the given path, storage or URL (will use file.travis.org if -d is given without a string)'

        def download(box = Travis::Worker.config.env)
          self.box = box

          download_box
        rescue => e
          puts e.message
        end

        desc 'create [BOX]', 'Creates the VirtualBox boxes from a base box (BOX defaults to Travis::Worker.config.env)'
        method_option :reset,    :aliases => '-r', :type => :boolean, :default => false, :desc => 'Force reset on virtualbox settings and boxes'

        def create(box = Travis::Worker.config.env)
          self.box = box

          vbox.reset if options[:reset]
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

          def download_box
            # make sure we remove old boxes before downloading new ones. Otherwise wget will append .1, .2 and so on
            # to the name of the file and import operation will import the old box. MK.
            run "rm -rf #{base_box}"
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
            vagrant.cli("box", "add", "travis-#{box}", base_box)
            vagrant.boxes.reload!
            vagrant.reload!
          end

          def up
            vagrant.cli("up")
          end

          def halt
            vagrant.cli("halt")
          end

          def vagrant
            @vagrant ||= ::Vagrant::Environment.new(:ui_class => ::Vagrant::UI::Colored)
          end
      end
    end
  end
end
