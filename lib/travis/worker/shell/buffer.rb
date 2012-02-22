module Travis
  class Worker
    module Shell
      class Buffer < String
        attr_reader :pos, :interval, :limit, :callback

        def initialize(interval = nil, options = {}, &callback)
          @interval = interval
          @callback = callback
          @limit = options[:limit] || Travis::Worker.config.limits.log_length
          @pos = 0

          start if interval
        end

        def <<(other)
          super.tap do
            limit_exeeded! if length > limit
          end
        end

        protected

          def flush
            read.tap do |string|
              callback.call(string) if callback
            end if !empty?
          end

          def empty?
            pos == length
          end

          def read
            string = self[pos, length - pos]
            @pos += string.length
            string
          end

          def start
            @thread = Thread.new do
              loop do
                flush
                sleep(interval) if interval
              end
            end
          end

          def limit_exeeded!
            raise Travis::Build::OutputLimitExceeded.new(limit.to_s)
          end
      end
    end
  end
end
