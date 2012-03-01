module Travis
  class Worker
    module Shell
      class Buffer < String
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
            # make sure limit is initialized and > 0. Appending here happens
            # asynchronously and #initialize may or may not have finished running
            # by then. In addition, #length here is a regular method which is not
            # synchronized. All this leads to #limit_exeeded! being called
            # too early (and this explains build logs w/o any output but this length limit
            # system message). MK.
            limit_exeeded! if @limit && (@limit > 0) && length > @limit
          end
        end

        def flush
          read.tap do |string|
            callback.call(string) if callback
          end if !empty?
        end

        def empty?
          pos == length
        end

        protected

          def read
            string = self[pos, length - pos]
            # This Update do not happen atomically but it has no practical difference: in case
            # total length was updated between local assignment above, we will just read and flush this
            # extra output during next loop tick.
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
