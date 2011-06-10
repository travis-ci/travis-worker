require 'uri'
require 'yaml'
require 'hashie'
# require 'active_support/core_ext/hash/keys'

module Travis
  module Job
    class Repository
      class Config < Hashie::Mash
        include Shell

        def gemfile?
          exec "test -f #{self.gemfile || 'Gemfile'}", :echo => false
        end

        def script
          self['script'] ||= gemfile? ? 'bundle exec rake' : 'rake'
        end
      end
    end
  end
end
