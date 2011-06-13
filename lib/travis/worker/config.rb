require 'yaml'
require 'hashie/dash'

module Travis
  class Worker
    DIRECTORIES = ['.', '~', '/etc']

    # Environment-aware worker configuration.
    #
    # ### Environment variables
    #
    # Environment (development, test, production and so on) is set using TRAVIS_ENV env variable, default value is *test*.
    # Redis connection URI is set using REDIS_URL env variable.
    #
    # @see Travis::Job::Base
    class Config < Hashie::Dash

      #
      # API
      #

      property :redis,    :default => Hashie::Mash.new(:url => ENV['REDIS_URL'])
      property :reporter, :default => Hashie::Mash.new(:http => Hashie::Mash.new)
      property :shell,    :default => Hashie::Mash.new(:buffer => 0)

      def initialize
        super(Hashie::Mash.new(load[environment]))
      end

      # @return [String] Environment Travis worker runs in. Typically one of: development, test, staging, production
      def environment
        ENV['TRAVIS_ENV'] || 'test'
      end

      def load
        YAML.load_file(filename)
      end

      def filename
        DIRECTORIES.each do |directory|
          filename = File.expand_path('.travis.yml', directory)
          return filename if File.exists?(filename)
        end
        raise "Could not find a .travis.yml configuration file. Valid locations are: #{DIRECTORIES.join(',')}"
      end
    end # Config
  end # Worker
end # Travis
