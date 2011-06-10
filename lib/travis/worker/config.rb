require 'yaml'
require 'hashie/dash'

module Travis
  class Worker
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

      def initialize
        # TODO currently expects a file to be present in the current working directory. should probably check
        # some other common places, too? like ~/.travis.config.yml or something
        super(Hashie::Mash.new(load[environment]))
      end

      # @return [String] Environment Travis worker runs in. Typically one of: development, test, staging, production
      def environment
        ENV['TRAVIS_ENV'] || 'test'
      end

      def load
        YAML.load_file(File.expand_path('config.yml'))
      end
    end # Config
  end # Worker
end # Travis
