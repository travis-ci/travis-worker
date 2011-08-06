module Travis
  module Worker
    module Builders

      module Ruby
        class Config < Hashr
          def rvm
            super ? Array(super).join : 'default'
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

            def expand_gemfile(gemfile)
              gemfile.empty? ? 'Gemfile' : gemfile
            end
        end

        class Commands < Base
          def setup_env
            exec "rvm use #{config.rvm}"
            exec "export BUNDLE_GEMFILE=#{pwd}/#{config.gemfile}" if config.gemfile?
            super
          end

          def install_dependencies
            install? ? exec("bundle install #{config.bundler_args}".strip, :timeout => :install_deps) : super
          end

          protected
            # @api plugin
            def install?
              config.gemfile?
            end
        end
      end

    end
  end
end