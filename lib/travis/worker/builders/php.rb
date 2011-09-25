module Travis
  module Worker
    module Builders

      module Php
        class Config < Base::Config
          def php_version
            normalize(super, '5.3.8')
          end

          def script
            if !self[:script].nil?
              self[:script]
            else
              'phpunit'
            end
          end
        end

        class Commands < Base::Commands
          def initialize(config)
            @config = Config.new(config)
          end

          def setup_env
            exec "phpenv php-#{config.php_version}"
            super
          end

        end
      end # Php

    end # Builders
  end # Worker
end # Travis

