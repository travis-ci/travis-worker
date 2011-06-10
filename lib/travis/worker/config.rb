require "hashie/dash"

module Travis
  class Worker
    # Environment-aware worker configuration.
    #
    # Environment (`development`, `test`, `production` and so on) is set using TRAVIS_ENV env variable, default value is `test`.
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
        super(Hashie::Mash.new(YAML.load_file('config/travis.yml')[environment]))
      end

      # @return [String] Environment Travis worker runs in. Typically one of: development, test, staging, production
      def environment
        ENV['TRAVIS_ENV'] || 'test'
      end
    end # Config
  end # Worker
end # Travis
