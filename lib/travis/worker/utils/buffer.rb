require 'travis/support/logging'

module Travis
  module Worker
    module Utils
      class Buffer < String
        include Logging

        class OutputLimitExceededError < StandardError
          attr_reader :limit
          def initialize(limit)
            @limit = limit
            super("The log length has exceeded the limit of #{limit} Megabytes (this usually means that test suite is raising the same exception over and over).\n\nThe build has been terminated.")
          end
        end

        log_header { "#{@log_header}:worker:utils:buffer" }

        attr_reader :pos, :interval, :limit, :callback, :stopped, :bytes_limit, :last_flushed

        def initialize(interval = nil, options = {}, &callback)
          @interval = interval
          @callback = callback

          @log_header = options[:log_header]

          @limit = options[:limit] || Travis::Worker.config.limits.log_length
          @bytes_limit = limit * 1024 * 1024

          # mark from which next read operation will start. In other words,
          # we read [mark, total length] substring every time we need to flush
          # the buffer and update the position.
          @pos = 0

          start if interval
        end

        def <<(other)
          super.tap do
            limit_exeeded! if length > bytes_limit
          end
        end

        def flush
          read.tap do |string|
            callback.call(string) if callback
            @last_flushed = Time.now.to_i
          end unless empty?
        end

        def reset
          replace ''
          @pos = 0
        end

        def empty?
          pos == length
        end

        def stop
          flush
          reset
          @stopped = true
        end

        protected

          def read
            string = self[pos, length - pos]
            # This update do not happen atomically but it has no practical
            # difference: in case total length was updated between local
            # assignment above and increment below, we will just read and flush
            # this extra output during next loop tick.
            @pos += string.length
            string
          end

          def start
            @last_flushed = Time.now.to_i
            @thread = Thread.new do
              loop do
                flush
                sleep(interval) if interval
                break if stopped
              end
            end
          end

          def limit_exeeded!
            return if @errored
            @errored = true
            warn "Log limit exceeded: @limit = #{bytes_limit}, length = #{self.length}"
            stop
            raise OutputLimitExceededError.new(limit.to_s)
          end

      end
    end
  end
end
