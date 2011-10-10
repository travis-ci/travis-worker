module Travis
  module Worker
    class Reporter
      ROUTING_KEY = 'reporting.jobs'

      attr_reader :exchange

      def initialize(exchange)
        @exchange = exchange
      end

      def notify(event)
        message(event.type, event.data)
      end

      protected

        def message(type, data)
          exchange.publish(data, :type => type.to_s, :routing_key => ROUTING_KEY) # do we really need to re-specify the key here?
        end
    end
  end
end
