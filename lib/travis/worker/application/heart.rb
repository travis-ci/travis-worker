require 'multi_json'
require 'travis/worker/utils/serialization'

module Travis
  module Worker
    class Application
      class Heart
        include Celluloid
        include Logging
        include Utils::Serialization

        attr_reader :exchange, :interval, :application

        def initialize(channel, &block)
          @status   = block
          @interval = Travis::Worker.config.heartbeat.interval
          @channel  = channel
          @exchange = @channel.default_exchange

          @target_queue_name = 'reporting.workers'

          declare_queues
        end

        def start
          beat
          @timer = every(interval) { beat }
        end

        def beat
          current = status

          debug current.inspect

          data = encode(current)
          options = {
            :properties => { :type => 'worker:status' },
            :routing_key => @target_queue_name,
            :uuid => Travis.uuid
          }
          exchange.publish(data, options)
        end

        def status
          @status.call
        end

        def stop
          @timer.cancel if @timer
        end

        def declare_queues
          @channel.queue(@target_queue_name, :durable => true)
        end
      end
    end
  end
end
