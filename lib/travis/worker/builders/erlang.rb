module Travis
  module Worker
    module Builders

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

          def install
            if !self[:install].nil?
              self[:install]
            elsif rebar_config_exists?
              './rebar get-deps'
            else
              nil
            end
          end
        end

        class Commands < Base::Commands
          def initialize(config)
            @config = Config.new(config)

            @config.rebar_config_exists = rebar_config?
          end

          def setup_env
            exec "source /home/vagrant/otp/#{config.otp_release}/activate"
            super
          end

          private
            def rebar_config?
              file_exists?('rebar.config') || file_exists?('Rebar.config')
            end
        end
      end # Erlang

    end # Builders
  end # Worker
end # Travis
