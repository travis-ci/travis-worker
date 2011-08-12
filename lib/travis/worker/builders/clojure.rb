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
        end

        class Commands < Base::Commands
          def initialize(config)
            @config = Config.new(config)
          end

          def install_dependencies
            exec("lein deps", :timeout => :install_deps)
            super
          end # def
        end # Commands
      end # Clojure
    end # Builders
  end # Worker
end # Travis
