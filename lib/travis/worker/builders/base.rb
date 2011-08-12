require 'hashr'

module Travis
  module Worker
    module Builders

      module Base
        class Config < Hashr
          protected
            def normalize(values, default)
              values ? Array(values).join : default
            end
        end

        class Commands
          include Shell

          attr_reader :config

          def initialize(config)
            @config = Config.new(config)
          end

          def run
            setup_env
            install_dependencies && run_scripts
          end

          def install_dependencies
            true
          end

          def setup_env
            Array(config.env).each { |env| exec "export #{env}" unless env.empty? } if config.env
          end

          def run_scripts
            %w{before_script script after_script}.each do |type|
              script = config.send(type)
              return false if script && !run_script(script, :timeout => type)
            end && true
          end

          def run_script(script, options = {})
            (script.is_a?(Array) ? script : script.split("\n")).each do |script|
              return false unless exec(script, options)
            end && true
          end

          protected
            def pwd
              @pwd ||= evaluate('pwd').strip
            end

            def file_exists?(file_name)
              exec("test -f #{file_name}", :echo => false)
            end
        end
      end

    end
  end
end