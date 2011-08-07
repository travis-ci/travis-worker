module Travis
  module Worker
    module Builders

      module Erlang
        class Config < Hashr
          def otp_release
            super ? Array(super).join : 'R14B02'
          end

          def script
            self[:script] ||= (rebar? ? 'rebar eunit' : 'make test')
          end

          def rebar?
            self[:rebar].nil? ? true : self[:rebar]
          end
        end

        class Commands < Base
          def setup_env
            exec "source /home/vagrant/otp/#{config.otp_release}/activate"
            super
          end

          def install_dependencies
            config.rebar? ? exec('rebar get-deps', :timeout => :install_deps) : super
          end

          protected
            def install?
              config.rebar? || execute("[ -f #{pwd}/rebar.config ]") || execute("[ -f #{pwd}/Rebar.config ]")
            end
        end
      end

    end
  end
end
