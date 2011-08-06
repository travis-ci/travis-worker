module Travis
  module Worker
    module Builders

      class Erlang
        class Config < Hashr
          def otp_release
            super ? Array(super).join : 'R14B02'
          end

          def script
            self[:script] ||= 'rebar eunit'
          end

          def rebar?
            self[:rebar] || true
          end
        end

        class Commands
          include Shell

          attr_reader :config

          def initialize(config)
            @config = Config.new(config)
          end

          # @api public
          def install
            rebar? ? exec('rebar get-deps', :timeout => :install_deps) : true
          end

          def setup_env
            exec "source /home/vagrant/otp/#{config.otp_release}/activate"
            Array(config.env).each { |env| exec "export #{env}" unless env.empty? } if config.env
          end

          def run_scripts
            %w{before_script script after_script}.each do |type|
              script = config.send(type)
              return false if script && !run_script(script, :timeout => type)
            end && true
          end

          protected
            # @api plugin
            def install?
              config.rebar?
            end

            def pwd
              @pwd ||= evaluate('pwd').strip
            end
        end
      end

    end
  end
end