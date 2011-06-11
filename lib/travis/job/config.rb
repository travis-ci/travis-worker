require 'faraday'

module Travis
  module Job
    # Build configuration job: read .travis.yml and return it
    class Config < Base
      attr_reader :config

      def start
      end

      def update(data)
      end

      def finish
        notify(:finish, :config => config)
      end

      protected

        def perform
          @config = fetch
        end

        def fetch
          parse(Faraday.get(url).body)
        end

        def url
          "#{repository.raw_url}/#{build.commit}/.travis.yml"
        end

        def parse(yaml)
          YAML.load(yaml) || {} rescue {}
        end
    end
  end
end
