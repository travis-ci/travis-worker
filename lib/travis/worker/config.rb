require 'yaml'
require 'hashr'
require 'socket'

module Travis
  class Worker
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
             :shell     => { :buffer => 0 },
             :timeouts  => { :hard_limit => 2400, :before_install => 300, :install => 300, :before_script => 300, :script => 600, :after_script => 300 },
             :vms       => { :count => 1, :_include => Vms },
             :limits    => { :log_length => 4 * 1024 * 1024 }

      def name
        @name ||= host.split('.').first
      end

      def host
        @host ||= Socket.gethostname
      end

      def names
        @names ||= VirtualMachine::VirtualBox.vm_names.map { |name| name.gsub(/^travis-/, '') }
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
