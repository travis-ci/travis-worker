module Travis
  module Worker
    module Logging
      autoload :Logger, 'travis/worker/logging/logger'

      class << self
        def io
          @io ||= $stdout
        end

        def io=(io)
          @io = io
        end
      end

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
          clazz = self.class.name
          arguments = (options[:params] == false ? nil : args)
          logger.log(:before, clazz, name, arguments) unless options[:only] == :after
          super.tap do |result|
            logger.log(:after, clazz, name) unless options[:only] == :before
          end
        end
      end

    end
  end
end
