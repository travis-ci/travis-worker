module Travis
  module Worker
    module Logging
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
        @proxy ||= Module.new
      end

      def log(name, options = {})
        proxy.send(:define_method, name) do |*args|
          logger.log(:before, name, args) unless options[:only] == :after
          super.tap do |result|
            logger.log(:after, name) unless options[:only] == :before
          end
        end
      end

      class Logger
        ANSI = {
          :red    => 31,
          :green  => 32,
          :yellow => 33
        }

        attr_reader :header

        def initialize(header)
          @header = header
        end

        def io
          Logging.io
        end

        def log(type, method, args = nil)
          args = "(#{args.map { |arg| arg.inspect}.join(', ')})" if args && !args.empty?
          message = "#{type} :#{method}#{args}"
          io.puts format(message)
        end

        def format(message)
          yellow("[#{header}] #{message}")
        end

        def colorize(color, text)
          "\e[#{ANSI[color]}m#{text}\e[0m"
        end

        ANSI.keys.each do |color|
          define_method(color) do |text|
            colorize(color, text)
          end
        end
      end
    end
  end
end
