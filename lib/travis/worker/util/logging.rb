module Travis
  module Worker
    module Util
      module Logging
        def new(*)
          super.tap do |instance|
            (class << instance; self; end).send(:include, proxy)
          end
        end

        def proxy
          @proxy ||= Module.new do
            def log_error(error)
              logger.error(error)
            end
          end
        end

        def log(name, options = {})
          proxy.send(:define_method, name) do |*args|
            arguments = options[:params].is_a?(FalseClass) ? [] : [args]
            logger.before(name, *arguments) unless options[:only] == :after
            super.tap do |result|
              logger.after(name) unless options[:only] == :before
            end
          end
        end
      end
    end
  end
end
