require 'uri'
require 'yaml'
require 'hashie'
# require 'active_support/core_ext/hash/keys'

module Travis
  module Job
    class Repository
      class Config < Hashie::Mash
        # ENV_KEYS = ['rvm', 'gemfile', 'env']

        # class << self
        #   def matrix?(config)
        #     config.values_at(*ENV_KEYS).compact.any? { |value| value.is_a?(Array) && value.size > 1 }
        #   end
        # end

        # def initialize(config = {})
        #   replace(config.stringify_keys)
        # end

        def gemfile?
          File.exists?(File.expand_path((self.gemfile || 'Gemfile').to_s))
        end

        def script
          self['script'] ||= gemfile? ? 'bundle exec rake' : 'rake'
        end
      end
    end
  end
end
