module Travis
  module Worker
    module Builder

      module NodeJs
        class Config < Base::Config
          def nodejs_version
            normalize(self[:nodejs], '0.4.11')
          end

          def package_exists?
            !!self[:package_exists]
          end

          def script
            if !self[:script].nil?
              self[:script]
            elsif package_exists?
              'npm test'
            else
              'make test'
            end
          end
        end

        class Commands < Base::Commands
          def initialize(config)
            @config = Config.new(config)
            @config.package_exists = file_exists?('package.json')
          end

          def setup_env
            exec("nvm use v#{config.nodejs_version}")
            super
          end

          def install_dependencies
            exec("npm install #{config.npm_args}".strip, :timeout => :install_deps) if config.package_exists?
            super
          end
        end
      end

    end
  end
end

