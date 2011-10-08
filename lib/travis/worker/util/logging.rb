module Travis
  module Worker
    module Util
      module Logging
        def announce(messages)
          messages = messages.split("\n") if messages.is_a?(String)
          messages.each do |msg|
            puts "#{format_logging_header}#{msg}"
          end
        end

        def announce_error
          announce("#{$!.class.name}: #{$!.message}")
          announce($@)
        end

        private
          def format_logging_header
            if header = Thread.current[:logging_header]
              "[#{yellow(header)}] "
            elsif respond_to?(:logging_header)
              "[#{yellow(self.logging_header)}] "
            else
              ""
            end
          end

          def colorize(text, color_code)
            "#{color_code}#{text}\e[0m"
          end

          def red(text);    colorize(text, "\e[31m"); end
          def green(text);  colorize(text, "\e[32m"); end
          def yellow(text); colorize(text, "\e[33m"); end
      end
    end
  end
end
