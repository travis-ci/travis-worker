require 'uri'
require 'yaml'
require 'hashie'
# require 'active_support/core_ext/hash/keys'

module Travis
  module Worker
    module Job
      class Repository
        class Config < Hashr
          include Shell

          def pwd
            @pwd ||= evaluate('pwd').strip
          end

          def rvm
            super ? Array(super).join : nil
          end

          def gemfile?
            exec "test -f #{gemfile}", :echo => false
          end

          def gemfile
            "#{pwd}/#{super || 'Gemfile'}"
          end

          def script
            self[:script] ||= gemfile? ? 'bundle exec rake' : 'rake'
          end
        end
      end # Repository
    end # Job
  end # Worker
end # Travis
