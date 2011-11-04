module Travis
  module Worker
    class Worker
      class Heart
        attr_reader :thread, :name, :host, :interval

        def initialize(name, host, interval)
          @name = name
          @host = host
          @interval = interval
        end

        def beat
          @thread ||= Thread.new do
            reporter.notify(event)
            sleep(interval)
          end
        end

        def stop
          thread.terminate if thread
        end

        def event
          @event ||= Travis::Build::Event.new(:'worker:ping', self, :name => name, :host => host)
        end
      end
    end
  end
end
