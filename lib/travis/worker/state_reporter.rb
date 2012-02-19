require "multi_json"

module Travis
  class Worker
    class StateReporter
      include Logging

      log_header { "reporter:#{name}" }

      attr_reader :name, :jobs, :workers

      def initialize(name, channel)
        @name     = name
        @channel  = channel

        @exchange = @channel.default_exchange
        @target_queue_name = 'reporting.workers'

        declare_queues
      end

      def notify(event, data)
        message(event, data)
      end

      def message(event, data)
        @exchange.publish(encode(data), :properties => { :type => event })
      end
      log :message, :as => :debug

      def encode(data)
        MultiJson.encode(data)
      end

      def declare_queues
        @channel.queue(@target_queue_name, :durable => true)
      end
    end
  end
end
