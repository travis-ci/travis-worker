module Travis
  module Worker
    module Builders

      class Ruby
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

        class Commands
          include Shell

          attr_reader :config

          def initialize(config)
            @config = Config.new(config)
          end

          # @api public
          def install
            install? ? exec("bundle install #{config.bundler_args}".strip, :timeout => :install_deps) : true
          end

          def setup_env
            exec "rvm use #{config.rvm}"
            exec "export BUNDLE_GEMFILE=#{pwd}/#{config.gemfile}" if config.gemfile?
            Array(config.env).each { |env| exec "export #{env}" unless env.empty? } if config.env
          end

          def run_scripts
            %w{before_script script after_script}.each do |type|
              script = config.send(type)
              return false if script && !run_script(script, :timeout => type)
            end && true
          end

          protected
            # @api plugin
            def install?
              config.gemfile?
            end

            def pwd
              @pwd ||= evaluate('pwd').strip
            end
        end
      end

    end
  end
end