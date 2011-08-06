require 'hashr'

module Travis
  module Worker
    module Builders

      class Config < Hashr; end

      class Base
        include Shell

        attr_reader :config

        def initialize(config)
          @config = Config.new(config)
        end

        def run
          setup_env
          install && run_scripts
        end

        # @api public
        def install
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
      end

    end
  end
end