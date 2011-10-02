module Travis
  module Worker
    module Builder

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
          def initialize(config, shell)
            @config = Config.new(config)
            @shell  = shell
          end

          def install_dependencies
            shell.execute("lein deps", :timeout => :install_deps)
            super
          end # def
        end # Commands
      end # Clojure

    end # Builders
  end # Worker
end # Travis
