require 'yaml'
require 'hashr'
require 'socket'
require 'travis/worker/virtual_machine'

module Travis
  module Worker
    class Config < Hashr
      module Vms
        def count
         self[:count]
        end

        def name_prefix
          "travis-#{Travis::Worker.config.env}"
        end

        def names
          (1..count.to_i).map { |num| "#{name_prefix}-#{num}" }
        end

        def provision?
          !recipes.empty? && File.directory?(cookbooks)
        end
      end

      define :amqp      => { :username => 'guest', :password => 'guest', :host => 'localhost' },
             :heartbeat => { :interval => 10 },
             :log_level => :info,
             :queue     => 'builds.common',
             :logging_channel => 'reporting.jobs.logs',
             :shell     => { :buffer => 0.5 },
             :timeouts  => { :hard_limit => 3000 },
             :vms       => { :provider => 'virtual_box', :count => 1, :_include => Vms },
             :limits    => { :log_length => 4, :last_flushed => 10 }

      def name
        @name ||= host.split('.').first
      end

      def names
        @names ||= VirtualMachine.provider.vm_names.map { |name| name.gsub(/^travis-/, '') }
      end
      
      def host
        @host ||= self[:host] || Socket.gethostname
      end

      def initialize
        super(read)
      end

      protected

        LOCATIONS = ['./config/', '~/.']

        def read
          local = read_yml(path)
          env   = local['env']
          local = local[env] || {}
          read_yml(path('base')).deep_merge(read_yml(path(env)).deep_merge(local.merge('env' => env)))
        end

        def read_yml(file_path)
          YAML.load_file(File.expand_path(file_path)) || {}
        end

        def config_filename(environment)
          ['worker', environment, 'yml'].compact.join('.')
        end

        def path(environment = nil)
          filename = config_filename(environment)
          paths    = LOCATIONS.map { |p| "#{p}#{filename}" }

          if existing_path = paths.detect { |p| File.exists?(p) }
            existing_path
          else
            raise "Could not find a configuration file. Valid paths are: #{paths.join(', ')}"
          end
        end
    end
  end
end
