module Travis
  module Worker
    module Builders

      module Clojure
        class Config < Hashr
          def script
            if !self[:script].nil?
              self[:script]
            else
              'lein test'
            end
          end
        end

        class Commands < Base
          def initialize(config)
            @config = Config.new(config)
          end

          def install_dependencies
            exec("lein deps", :timeout => :install_deps)
            super
          end
        end
      end
    end
  end
end