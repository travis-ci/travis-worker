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
          add_box from, :to => config.base_name
          exit unless up(config.base_name, :provision => true)
          package_box config.base_name

          1.upto(config.count) do |num|
            add_box config.base_name, :to => "#{config.name_prefix}-#{num}"
          end
          up
        end

        desc 'package', 'Package the worker-base.box'
        def package
          exit unless up config.base_name, :provision => true
          package_box config.base_name
        end

        desc 'import', 'Import the base.box to worker boxes'
        def import
          1.upto(config.count) do |num|
            add_box config.base_name, :to => "#{config.name_prefix}-#{num}"
          end
        end

        desc 'remove', 'Remove the worker boxes'
        def remove
          1.upto(config.count) do |num|
            destroy "#{config.name_prefix}-#{num}"
            remove_box "#{config.name_prefix}-#{num}"
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
            ENV['WITH_BASE'] = (name == config.base_name).inspect
            run "vagrant up #{name} --provision=#{options[:provision].inspect}"
          end

          def destroy(name)
            run "vagrant destroy #{name}"
          end

          def package_box(name)
            run "rm -rf #{name}.box"
            run "vagrant package --base #{uuid(name)}"
            run "mv package.box #{name}.box"
          end

          def uuid(name)
            vms = JSON.parse(File.read('.vagrant'))
            vms['active'][name] || raise("could not find #{name} uuid in #{vms.inspect}")
          end
      end
    end
  end
end
