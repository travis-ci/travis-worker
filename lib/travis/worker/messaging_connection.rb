require "hot_bunnies"

module Travis
  module Worker
    class MessagingConnection

      attr_reader :connection, :channel, :exchange, :builds_queue, :workers


      def initialize(configuration)
        @configuration = configuration

        @connection = @channel = @exchange = @build_queue = nil
      end

      def bind
        install_signal_traps

        connect_to_broker

        declare_queues
      rescue PossibleAuthenticationFailureException => e
        announce "[boot] Failed to authenticate with #{@connection.address.to_s} on port #{@connection.port}"
      rescue ConnectException => e
        announce "[boot] Failed to connect to #{@connection.address.to_s} on port #{@connection.port}"
      end

      def unbind
        self.announce("[shutdown] Closing connection to broker...")

        @connection.close

        self.announce("[shutdown] Connection to broker closed")
      end

      def prefetch
        default_channel.prefetch
      end

      def prefetch=(count)
        default_channel.prefetch = count
      end


      protected

      def connect_to_broker
        announce "[boot] About to connect..."

        @connection = HotBunnies.connect(connection_options)

        @default_exchange = @connection.default_exchange

        @default_channel = @connection.create_channel
        @default_channel.prefetch = configuration.vms.count

        announce "[boot] Connected to an AMQP broker at #{@connection.broker_endpoint} using username #{@connection.username}"
      end

      def declare_queues
        raise "Default channel is not initialized" unless @default_channel

        @build_requests_queue = @default_channel.queue('builds', :durable => true, :exculsive => false)
      end

      def connection_options
        configuration.slice(HotBunnies::CONNECTION_PROPERTIES)
      end

      def announce(what)
        puts what
      end

    end
  end
end
