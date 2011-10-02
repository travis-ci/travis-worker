module Travis
  module Worker
    module Builder

      module Ruby
        class Config < Base::Config
          def rvm
            normalize(super, 'default')
          end

          def gemfile
            normalize(super, 'Gemfile')
          end

          def gemfile_exists?
            !!self[:gemfile_exists]
          end

          def script
            if !self[:script].nil?
              self[:script]
            elsif gemfile_exists?
              'bundle exec rake'
            else
              'rake'
            end
          end
        end

        class Commands < Base::Commands
          def initialize(config, shell)
            @config = Config.new(config)
            @shell  = shell

            @config.gemfile_exists = file_exists?(@config.gemfile)
          end

          def setup_env
            shell.execute("rvm use #{config.rvm}")
            shell.execute("export BUNDLE_GEMFILE=#{pwd}/#{config.gemfile}") if config.gemfile_exists?
            super
          end

          def install_dependencies
            shell.execute("bundle install #{config.bundler_args}".strip, :timeout => :install_deps) if config.gemfile_exists?
            super
          end
        end
      end

    end
  end
end