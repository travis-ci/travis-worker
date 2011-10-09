module Travis
  module Worker
    module Logging
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

        def log(type, object, method, args = nil)
          args = "(#{args.map { |arg| arg.inspect}.join(', ')})" if args && !args.empty?
          message = "(#{object.class.name}) #{type} :#{method}#{args}"
          io.puts format(:yellow, message)
        end

        def error(exception)
          ["#{exception.class.name}: #{exception.message}", exception.backtrace].each do |message|
            io.puts format(:red, message)
          end
        end

        protected

          def format(color, message)
            colorized = colorize(color, "[#{header}]")
            "#{colorized} #{message}"
          end

          def colorize(color, text)
            "\e[#{ANSI[color]}m#{text}\e[0m"
          end
      end
    end
  end
end
