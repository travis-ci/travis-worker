module Travis
  class Worker
    class Application
      class Heart
        attr_reader :exchange, :thread, :interval, :status

        def initialize(&block)
          @status = block
          @interval = Travis::Worker.config.heartbeat.interval
          @exchange = Travis::Worker::Amqp::Publisher.status
        end

        def beat
          @thread ||= Thread.new do
            loop do
              begin
                sleep(interval)
                pump!
              rescue Exception => e
                puts e.message, e.backtrace
                break
              end
            end
          end
        end

        def pump!
          exchange.publish(status.call, :properties => { :type => 'worker:status' })
        end

        def stop
          thread.terminate if thread
        end
      end
    end
  end
end
