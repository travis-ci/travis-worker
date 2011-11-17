module Travis
  module Worker
    class Logger
      ANSI = {
        :red    => 31,
        :green  => 32,
        :yellow => 33
      }

      attr_reader :header, :io

      def initialize(header, io = STDOUT)
        @header = header
        @io = io
      end

      def log(message)
        io.puts format(:yellow, message)
      end

      def before(method, args = [])
        io.puts format(:yellow, "about to #{method}#{format_args(args)}")
      end

      def after(method)
        io.puts format(:yellow, "done: #{method}")
      end

      def error(exception)
        messages = ["#{exception.class.name}: #{exception.message}"] + exception.backtrace
        messages.each { |message| io.puts format(:red, message) }
      end

      protected

        def format(color, message)
          colorized = colorize(color, "[#{header}]")
          "#{colorized} #{message}"
        end

        def format_args(args)
          args.empty? ? '' : "(#{args.map { |arg| format_arg(arg).inspect }.join(', ')})"
        end

        def format_arg(arg)
          if arg.is_a?(Hash) && arg.key?(:log) && arg[:log].size > 80
            arg = arg.dup
            arg[:log] = "#{arg[:log][0..80]} ..."
          end
          arg
        end

        def colorize(color, text)
          "\e[#{ANSI[color]}m#{text}\e[0m"
        end
    end
  end
end
