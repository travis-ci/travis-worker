require 'hashr'

module Travis
  module Worker
    module Builders

      module Base
        class Config < Hashr
          # this is needed because of rake and fileutils
          # getting mixed into the global namespace :'(
          undef :install

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
            run_install_dependencies && run_scripts
          end

          def setup_env
            Array(config.env).each { |env| exec "export #{env}" unless env.empty? } if config.env
          end

          def run_install_dependencies
            run_command_set(:before_install, :install, :after_install)
          end

          def run_scripts
            run_command_set(:before_script, :script, :after_script)
          end

          def run_command_set(*command_set)
            command_set.each do |type|
              command = config.send(type)
              return false if command && !run_command(command, :timeout => type)
            end && true
          end

          def run_command(command, options = {})
            (command.is_a?(Array) ? command : command.split("\n")).each do |command|
              return false unless exec(command, options)
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