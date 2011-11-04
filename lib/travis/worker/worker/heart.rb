module Travis
  module Worker
    class Worker
      class Heart
        attr_reader :thread, :name, :host, :interval, :callback

        def initialize(name, &block)
          @name = name
          @callback = block
          @host = Travis::Worker.hostname
          @interval = Travis::Worker.config.heartbeat.interval
        end

        def beat
          @thread ||= Thread.new do
            loop do
              callback.call(:'worker:ping', :name => name, :host => host)
              sleep(interval)
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
