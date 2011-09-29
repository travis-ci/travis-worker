module Travis
  module Worker
    class Reporter

      ROUTING_KEY = 'reporting.jobs'

      attr_reader :exchange

      def initialize(channel)
        @exchange = channel.exchange('', :type => :direct, :durable => true)
      end

      def on_start(data)
        message(:start, data)
      end

      def on_update(data)
        message(:update, data, :incremental => true)
      end

      def on_finish(data)
        message(:finish, data)
      end

      def message(type, data, options = {})
        exchange.publish(data, :type => type.to_s, :routing_key => ROUTING_KEY, :arguments => { 'x-incremental' => !!options[:incremental] })
      end

    end
  end
end
