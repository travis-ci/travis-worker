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
        method_option :immute,   :aliases => '-i', :type => :boolean, :default => false, :desc => 'Make all disks in the current vagrant environment immutable'
        method_option :snapshot, :aliases => '-s', :type => :boolean, :default => true,  :desc => 'Take online snapshots of all vms'
        method_option :reset,    :aliases => '-r', :type => :boolean, :default => false, :desc => 'Force reset on virtualbox settings and boxes'
        method_option :local,    :aliases => '-l', :type => :boolean, :default => true,  :desc => 'Copy the packaged base box from ../travis-boxes/boxes to ./boxes otherwise upload them to s3'

        def update
          vbox.reset if options[:reset]

          remove_base_box

          options[:local] ? local : download

          add_box
          exit unless up
          halt
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
            "boxes/travis-#{env}.box"
          end

          def remove_base_box
            run "rm -rf boxes/travis-#{env}.box"
          end

          def local
            run "cp ../travis-boxes/boxes/travis-#{env}.box boxes" # TODOdon't copy if files are identical
          end

          # def download
          #   run "wget http://files.vagrantup.com/#{from}.box" unless File.exists?("#{from}.box")
          # end

          def add_box
            run "vagrant box add travis-#{env} #{base}"
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
