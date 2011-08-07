module Travis
  module Worker
    module Builders

      module Ruby
        class Config < Hashr
          def rvm
            super || 'default'
          end

          def gemfile
            super || 'Gemfile'
          end

          def script
            self[:script] ||= gemfile? ? 'bundle exec rake' : 'rake'
          end
        end

        class Commands < Base
          def initialize(config)
            @config = Config.new(config)
          end

          def setup_env
            exec "rvm use #{config.rvm}"
            exec "export BUNDLE_GEMFILE=#{pwd}/#{config.gemfile}" if config.gemfile?
            super
          end

          def install_dependencies
            install? ? exec("bundle install #{config.bundler_args}".strip, :timeout => :install_deps) : super
          end

          protected
            def install?
              exec "test -f #{gemfile}", :echo => false
            end
        end
      end

    end
  end
end