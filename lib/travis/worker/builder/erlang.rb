module Travis
  module Worker
    module Builder

      module Erlang
        class Config < Base::Config
          def otp_release
            normalize(super, 'R14B02')
          end

          def rebar_config_exists?
            !!self[:rebar_config_exists]
          end

          def script
            if !self[:script].nil?
              self[:script]
            elsif rebar_config_exists?
              './rebar compile && ./rebar skip_deps=true eunit'
            else
              'make test'
            end
          end
        end

        class Commands < Base::Commands
          def initialize(config, shell)
            @config = Config.new(config)
            @shell  = shell

            check_for_rebar_config
          end

          def setup_env
            shell.execute "source /home/vagrant/otp/#{config.otp_release}/activate"
            super
          end

          def install_dependencies
            if config.rebar_config_exists?
              shell.execute('./rebar get-deps', :timeout => :install_deps)
            else
              true
            end
          end

          private
            def check_for_rebar_config
              rebar = file_exists?('rebar.config') || file_exists?('Rebar.config')
              @config.rebar_config_exists = rebar
            end
        end
      end # Erlang

    end # Builders
  end # Worker
end # Travis
