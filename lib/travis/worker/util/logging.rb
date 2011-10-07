module Travis
  module Worker
    module Util
      module Logging
        def announce(message)
          message.split("\n").each do |msg|
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
              "[#{header}] "
            elsif respond_to?(:logging_header)
              "[#{self.logging_header}] "
            else
              ""
            end
          end
      end
    end
  end
end
