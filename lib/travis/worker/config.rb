module Travis
  class Worker
    class Config < Hashie::Dash
      property :redis,    :default => Hashie::Mash.new(:url => ENV['REDIS_URL'])
      property :reporter, :default => Hashie::Mash.new(:http => Hashie::Mash.new)

      def initialize
        super(Hashie::Mash.new(YAML.load_file('config/travis.yml')[environment]))
      end

      def environment
        ENV['TRAVIS_ENV'] || 'test'
      end
    end
  end
end
