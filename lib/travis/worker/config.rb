require 'yaml'

module Travis
  module Worker
    class Config < Hashr
      module Vms
        def count
         self[:count]
        end

        def names
          ['base'] + (1..count.to_i).map { |num| "worker-#{num}" }
        end

        def recipes?
          !!recipes && !recipes.empty?
        end
      end

      default :queue    => 'builds',
              :amqp     => { :username => 'guest', :password => 'guest', :host => 'localhost', :vhost => 'travis' },
              :redis    => { :url => nil },
              :reporter => { :http => { :url => nil } },
              :shell    => { :buffer => 0 },
              :timeouts => { :before_script => 120, :after_script => 120, :script => 600, :bundle => 300 },
              :vms      => { :count => 1, :base => 'lucid32', :memory => 1536, :cookbooks => 'vendor/cookbooks', :log_level => 'info', :json => {} }

      def initialize
        super(read)
        class << self.vms
          include Vms
        end
      end

      protected

        LOCATIONS = ['./config/', '~/.']

        def read
          base = read_yml(path)
          base.key?('env') ? read_yml(path(base['env'])).merge(base) : base
        end

        def read_yml(path)
          YAML.load_file(File.expand_path(path))
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
