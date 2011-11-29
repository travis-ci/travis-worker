module Travis
  class Worker
    class Reporter
      include Logging

      log_header { "reporter:#{name}" }

      attr_reader :name, :exchange

      def initialize(name, exchange)
        @name = name
        @exchange = exchange
      end

      def notify(event)
        message(event.name, event.data)
      end

      def message(type, data)
        exchange.publish(data, :properties => { :type => type.to_s })
      end
      log :message, :as => :debug
    end
  end
end
