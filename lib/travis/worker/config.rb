require 'yaml'
require 'hashie/dash'

module Travis
  module Worker
    DIRECTORIES = ['.', '~', '/etc']

    class Config < Hashie::Dash
      autoload :Vagrant, 'travis/worker/config/vagrant'

      #
      # API
      #

      property :amqp,     :default => Hashie::Mash.new(:username => "guest", :password => "guest", :host => "localhost", :vhost => "travis")

      property :redis,    :default => Hashie::Mash.new(:url => ENV['REDIS_URL'])
      property :reporter, :default => Hashie::Mash.new(:http => Hashie::Mash.new)
      property :shell,    :default => Hashie::Mash.new(:buffer => 0)
      property :workers,  :default => 3
      property :timeouts, :default => Hashie::Mash.new(:before_script => 120, :after_script => 120, :script => 600, :bundle => 300)

      def initialize
        config = load
        @vms = Vagrant.new(config.delete('vms') || {})
        super(Hashie::Mash.new(config))
      end

      def vms
        @vms ||= Vagrant::Config.new
      end

      def load
        YAML.load_file(filename)
      end

      def filename
        DIRECTORIES.each do |directory|
          filename = File.expand_path('.worker.yml', directory)
          return filename if File.exists?(filename)
        end
        raise "Could not find a .worker.yml configuration file. Valid locations are: #{DIRECTORIES.join(', ')}"
      end
    end # Config
  end # Worker
end # Travis
