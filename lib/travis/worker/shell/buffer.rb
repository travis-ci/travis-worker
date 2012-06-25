module Travis
  class Worker
    module Shell
      class Buffer < String
        include Logging

        log_header { 'travis:worker:shell:buffer' }

        attr_reader :pos, :interval, :limit, :callback

        def initialize(interval = nil, options = {}, &callback)
          @interval = interval
          @callback = callback
          @limit = options[:limit] || Travis::Worker.config.limits.log_length
          # mark from which next read operation will start. In other words,
          # we read [mark, total length] substring every time we need to flush
          # the buffer and update the position.
          @pos = 0

          start if interval
        end

        def <<(other)
          super.tap do
            limit_exeeded! if length > limit
          end
        end

        def flush
          read.tap do |string|
            callback.call(string) if callback
          end unless empty?
        end

        def stop
          flush
          @thread.terminate
        end

        def empty?
          pos == length
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
            @thread = Thread.new do
              loop do
                flush
                sleep(interval) if interval
              end
            end
          end

          def limit_exeeded!
            warn "Log limit exceeded: @limit = #{@limit.inspect}, length = #{self.length.inspect}"
            raise Travis::Build::OutputLimitExceeded.new(limit.to_s)
          end
      end
    end
  end
end
