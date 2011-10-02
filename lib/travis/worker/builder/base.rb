require 'hashr'

module Travis
  module Worker
    module Builder

      module Base
        class Config < Hashr
          protected
            def normalize(values, default)
              values ? Array(values).join : default
            end
        end

        class Commands

          attr_reader :config

          attr_reader :shell

          def initialize(config, shell)
            @config = Config.new(config)
            @shell  = shell
          end

          def run
            setup_env
            install_dependencies && run_scripts
          end

          def install_dependencies
            true
          end

          def setup_env
            Array(config.env).each { |env| shell.execute("export #{env}") unless env.empty? } if config.env
          end

          def run_scripts
            %w{before_script script after_script}.each do |type|
              script = config.send(type)
              return false if script && !run_script(script, :timeout => type)
            end && true
          end

          def run_script(script, options = {})
            (script.is_a?(Array) ? script : script.split("\n")).each do |script|
              return false unless shell.execute(script, options)
            end && true
          end

          protected
            def pwd
              @pwd ||= shell.evaluate('pwd').strip
            end

            def file_exists?(*file_names)
              file_names.any? do |file_name|
                shell.execute("test -f #{file_name}", :echo => false)
              end
            end
        end
      end

    end
  end
end