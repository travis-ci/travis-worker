module Travis
  module Worker
    module Builders

      module Erlang
        class Config < Hashr
          def otp_release
            super || 'R14B02'
          end

          def script
            if !self[:script].nil?
              self[:script]
            elsif rebar?
              'rebar eunit'
            else
              'make test'
            end
          end

          def rebar?
            self[:rebar].nil? ? false : self[:rebar]
          end
        end

        class Commands < Base
          def initialize(config)
            @config = Config.new(config)

            check_for_rebar
          end

          def setup_env
            exec "source /home/vagrant/otp/#{config.otp_release}/activate"
            super
          end

          def install_dependencies
            config.rebar? ? exec('rebar get-deps', :timeout => :install_deps) : true
          end

          protected
            def check_for_rebar
              if config.rebar.nil?
                config.rebar = execute("[ -f #{pwd}/rebar.config ]") || execute("[ -f #{pwd}/Rebar.config ]")
              end
            end
        end
      end

    end
  end
end
