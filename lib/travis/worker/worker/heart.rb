module Travis
  module Worker
    class Worker
      class Heart
        attr_reader :thread, :interval, :callback

        def initialize(&block)
          @callback = block
          @interval = Travis::Worker.config.heartbeat.interval
        end

        def beat
          @thread ||= Thread.new do
            loop do
              sleep(interval)
              callback.call
            end
          end
        end

        def stop
          thread.terminate if thread
        end
      end
    end
  end
end
