module Travis
  module Worker
    class Reporter
      attr_reader :build, :messages, :connections

      def initialize(channel)
        @channel  = Travis::Worker.amqp_connection.create_channel
        @exchange = Travis::Worker.amqp_connection.default_exchange
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
        @exchange.publish(data[:log], :type => type.to_s, :routing_key => "reporting.progress", :arguments => { 'x-incremental' => !!data[:incremental] })
      end
    end # Reporter
  end # Worker
end # Travis
