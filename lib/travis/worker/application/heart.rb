require "multi_json"

module Travis
  class Worker
    class Application
      class Heart

        #
        # Behaviors
        #

        include Serialization


        #
        # API
        #

        attr_reader :exchange, :thread, :interval, :status

        def initialize(channel, &block)
          @status   = block
          @interval = Travis::Worker.config.heartbeat.interval
          @channel  = channel
          @exchange = @channel.default_exchange

          @target_queue_name = 'reporting.workers'

          declare_queues
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
          exchange.publish(encode(status.call), :properties => { :type => 'worker:status' }, :routing_key => @target_queue_name)
        end

        def stop
          thread.terminate if thread
        end

        def encode(data)
          encode(data)
        end

        def declare_queues
          @channel.queue(@target_queue_name, :durable => true)
        end
      end
    end
  end
end
