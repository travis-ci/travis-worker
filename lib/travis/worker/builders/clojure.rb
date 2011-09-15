module Travis
  module Worker
    module Builders

      module Clojure
        class Config < Base::Config
          def script
            if !self[:script].nil?
              self[:script]
            else
              'lein test'
            end
          end

          def install
            if !self[:install].nil?
              self[:install]
            elsif rebar_config_exists?
              "lein deps"
            else
              nil
            end
          end
        end

        class Commands < Base::Commands
          def initialize(config)
            @config = Config.new(config)
          end
        end # Commands
      end # Clojure
    end # Builders
  end # Worker
end # Travis
