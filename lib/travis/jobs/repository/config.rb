require 'uri'
require 'yaml'
require 'active_support/core_ext/hash/keys'

module Travis
  module Jobs
    class Repository
      class Config < Hash
        ENV_KEYS = ['rvm', 'gemfile', 'env']

        class << self
          def matrix?(config)
            config.values_at(*ENV_KEYS).compact.any? { |value| value.is_a?(Array) && value.size > 1 }
          end
        end

        def initialize(config = {})
          replace(config.stringify_keys)
        end

        def gemfile?
          File.exists?(gemfile)
        end

        def gemfile
          @gemfile ||= File.expand_path((self['gemfile'] || 'Gemfile').to_s)
        end

        def before_script
          self['before_script']
        end

        def script
          self['script'] ||= gemfile? ? 'bundle exec rake' : 'rake'
        end

        def after_script
          self['after_script']
        end
      end
    end
  end
end
