require 'thor'
require 'yaml'
require 'json'
require 'travis/worker'

module Travis
  module Worker
    module Cli
      class Vagrant < Thor
        class << self
          def config
            Travis::Worker.config.vms
          end
        end

        namespace "travis:worker:vagrant"

        include Cli

        desc 'rebuild', 'Rebuild all worker vms'
        method_option :from,  :default => config.base
        method_option :force, :aliases => '-f', :type => :boolean, :default => false, :desc => 'Force reset on virtualbox settings and boxes'
        def rebuild
          vbox.reset

          download
          add_box from, :to => 'base'
          exit unless up 'base', :provision => true
          package_box 'base'

          1.upto(config.count) do |num|
            add_box 'base', :to => "worker-#{num}"
          end
          up
        end

        desc 'package', 'Package the base.box'
        def package
          exit unless up 'base', :provision => true
          package_box 'base'
        end

        desc 'import', 'Import the base.box to worker boxes'
        def import
          1.upto(config.count) do |num|
            add_box 'base', :to => "worker-#{num}"
          end
        end

        desc 'remove', 'Remove the worker boxes'
        def remove
          1.upto(config.count) do |num|
            destroy "worker-#{num}"
            remove_box "worker-#{num}"
          end
        end

        protected

          def vbox
            @vbox ||= Vbox.new('', options)
          end

          def config
            self.class.config
          end

          def from
            options['from']
          end

          def download
            run "wget http://files.vagrantup.com/#{from}.box" unless File.exists?("#{from}.box")
          end

          def add_box(name, options = {})
            run "vagrant box add #{options[:to] || name} #{name}.box"
          end

          def remove_box(name)
            run "vagrant box remove #{name}"
          end

          def up(name = nil, options = { :provision => false })
            ENV['WITH_BASE'] = (name == 'base').inspect
            run "vagrant up #{name} --provision=#{options[:provision].inspect}"
          end

          def destroy(name)
            run "vagrant destroy #{name}"
          end

          def package_box(name)
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
