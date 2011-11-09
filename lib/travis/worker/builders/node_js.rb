module Travis
  module Worker
    module Builders

      module NodeJs
        class Config < Base::Config
          def node_js_version
            version_from_config = self[:node_js] || self[:nodejs]
            normalize(version_from_config, '0.4')
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

          def install
            if !self[:install].nil?
              self[:install]
            elsif package_exists?
              "npm install #{npm_args}".strip
            else
              nil
            end
          end
        end

        class Commands < Base::Commands
          def initialize(config)
            @config = Config.new(config)
            @config.package_exists = file_exists?('package.json')
          end

          def setup_env
            exec("nvm use #{config.node_js_version}")
            super
          end
        end
      end

    end
  end
end

