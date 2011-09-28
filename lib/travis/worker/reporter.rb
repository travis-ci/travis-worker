module Travis
  module Worker
    class Reporter

      attr_reader :exchange

      def initialize(channel)
        @exchange = channel.exchange('', :type => :direct, :durable => true)
      end

      def on_start(data)
        message(:start, data)
      end

      def on_update(data)
        message(:update, data.merge(:incremental => true))
      end

      def on_finish(data)
        message(:finish, data)
      end

      def message(type, data)
        exchange.publish(data, :type => type.to_s, :routing_key => "reporting", :arguments => { 'x-incremental' => !!data[:incremental] })
      end

    end
  end
end
