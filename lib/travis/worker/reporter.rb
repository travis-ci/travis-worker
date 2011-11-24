module Travis
  module Worker
    class Reporter
      include Logging

      attr_reader :exchange

      def initialize(exchange)
        @exchange = exchange
      end

      def notify(event)
        message(event.name, event.data)
      end

      def message(type, data)
        exchange.publish(data, :properties => { :type => type.to_s })
      end
      log :message
    end
  end
end
