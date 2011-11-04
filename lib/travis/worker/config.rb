require 'yaml'
require 'hashr'

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

      define :queue     => 'builds.ruby',
             :messaging => { :username => 'guest', :password => 'guest', :host => 'localhost' },
             :shell     => { :buffer => 0 },
             :timeouts  => { :before_script => 300, :after_script => 120, :script => 600, :install => 300 },
             :vms       => { :count => 1, :_include => Vms },
             :heartbeat => { :interval => 10 }

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

        def read_yml(path)
          YAML.load_file(File.expand_path(path)) || {}
        end

        def path(environment = nil)
          filename = ['worker', environment, 'yml'].compact.join('.')
          paths = LOCATIONS.map { |path| "#{path}#{filename}" }
          paths.each { |path| return path if File.exists?(path) }
          raise "Could not find a configuration file. Valid paths are: #{paths.join(', ')}"
        end
    end
  end
end
