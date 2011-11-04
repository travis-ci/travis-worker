module Travis
  module Worker
    class Reporter
      extend Util::Logging

      attr_reader :exchange, :logger

      def initialize(exchange, logger)
        @exchange = exchange
        @logger = logger
      end

      def notify(event)
        message(event.name, event.data)
      end

      protected

        def message(type, data)
          exchange.publish(data, :properties => { :type => type.to_s })
        end
        log :message
    end
  end
end
