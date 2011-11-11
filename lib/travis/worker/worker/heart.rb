module Travis
  module Worker
    class Worker
      class Heart
        attr_reader :thread, :worker, :host, :interval, :callback

        def initialize(worker, &block)
          @worker = worker
          @callback = block
          @host = Travis::Worker.hostname
          @interval = Travis::Worker.config.heartbeat.interval
        end

        def beat
          @thread ||= Thread.new do
            loop do
              callback.call(:'worker:ping', :name => worker.name, :host => host, :state => worker.state)
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
