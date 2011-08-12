module Travis
  module Worker
    module Builders

      module Erlang
        class Config < Hashr
          def otp_release
            super || 'R14B02'
          end

          def rebar_config_exists?
            !!self[:rebar_config_exists]
          end

          def script
            if !self[:script].nil?
              self[:script]
            elsif rebar_config_exists?
              './rebar eunit'
            else
              'make test'
            end
          end
        end

        class Commands < Base
          def initialize(config)
            @config = Config.new(config)

            check_for_rebar_config
          end

          def setup_env
            exec "source /home/vagrant/otp/#{config.otp_release}/activate"
            super
          end

          def install_dependencies
            if config.rebar_config_exists?
              exec('./rebar get-deps', :timeout => :install_deps)
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
      end

    end
  end
end
