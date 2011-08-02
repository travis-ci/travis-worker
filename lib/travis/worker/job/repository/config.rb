require 'uri'
require 'yaml'
require 'hashr'

module Travis
  module Worker
    module Job
      class Repository
        class Config < Hashr
          include Shell

          def rvm
            super ? Array(super).join : nil
          end

          def gemfile?
            exec "test -f #{gemfile}", :echo => false
          end

          def gemfile
            expand_gemfile(Array(super).join)
          end

          def script
            self[:script] ||= gemfile? ? 'bundle exec rake' : 'rake'
          end

          protected

            def pwd
              @pwd ||= evaluate('pwd').strip
            end

            def expand_gemfile(gemfile)
              "#{pwd}/#{gemfile.empty? ? 'Gemfile' : gemfile}"
            end
        end
      end # Repository
    end # Job
  end # Worker
end # Travis
