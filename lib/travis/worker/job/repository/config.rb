require 'uri'
require 'yaml'
require 'hashie'
# require 'active_support/core_ext/hash/keys'

module Travis
  module Job
    class Repository
      class Config < Hashie::Mash
        include Shell

        def pwd
          @pwd ||= evaluate('pwd').chomp
        end

        def rvm
          Array(super).join
        end

        def gemfile?
          exec "test -f #{gemfile}", :echo => false
        end

        def gemfile
          "#{pwd}/#{super || 'Gemfile'}"
        end

        def script
          self['script'] ||= gemfile? ? 'bundle exec rake' : 'rake'
        end
      end
    end
  end
end
