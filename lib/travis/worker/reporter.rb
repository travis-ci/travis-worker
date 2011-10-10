module Travis
  module Worker
    class Reporter
      attr_reader :exchange

      def initialize(exchange)
        @exchange = exchange
      end

      def notify(event)
        message(event.type, event.data)
      end

      protected

        def message(type, data)
          exchange.publish(data, :type => type.to_s)
        end
    end
  end
end
