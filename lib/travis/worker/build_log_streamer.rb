module Travis
  class Worker
    class BuildLogStreamer
      include Logging, Travis::Serialization

      log_header { "reporter:#{name}" }

      attr_reader :name, :jobs, :workers

      def initialize(name, channel, routing_key)
        @name        = name
        @channel     = channel
        @routing_key = routing_key

        @exchange    = @channel.exchange("reporting", :type => :topic, :durable => true)
      end

      def notify(event, data)
        message(event, data)
      end

      def message(event, data)
        @exchange.publish(encode(data), :properties => { :type => event }, :routing_key => @routing_key)
      end
      log :message, :as => :debug
    end
  end
end
