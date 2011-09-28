require 'hot_bunnies'

module Travis
  module Worker

    # Public: Represents a connection to the Travis messaging broker.
    #
    # The connection, main channel and exchange, and jobs queue are all
    # encapsulated and available from this class.
    class MessagingConnection

      # Public: Returns the messaging connection.
      attr_reader :connection

      # Public: Returns the channel for messaging communications.
      attr_reader :channel

      # Public: Returns the exchange for messaging communications.
      attr_reader :exchange

      # Public: Returns the jobs queue where jobs are published to.
      attr_reader :jobs_queue

      # Public: Initialize a MessagingConnection
      #
      # config - A Config to use for connection details (default: nil)
      def initialize(config = nil)
        @connection = @channel = @exchange = @jobs_queue = nil

        @config = config
      end

      # Public: Connects to the messaging broker.
      #
      # Along with connecting to the broker, queues are also declared and setup.
      def bind
        install_signal_traps

        connect_to_broker

        declare_queues
      rescue PossibleAuthenticationFailureException => e
        announce("[boot] Failed to authenticate with #{connection.address.to_s} on port #{connection.port}")
      rescue ConnectException => e
        announce("[boot] Failed to connect to #{connection.address.to_s} on port #{connection.port}")
      end

      # Public: Closes the connection to the messaging broker.
      #
      # As well as disconnecting from the messaging broker, all related connections to the jobs queue,
      # exchange and channel are also deleted or closed.
      def unbind
        announce("[shutdown] Closing connection to broker...")

        jobs_queue.delete
        exchange.delete
        channel.close
        connection.close

        announce("[shutdown] Connection to broker closed")
      end

      # Public: Returns the number of messages prefetched for the messaging channel.
      def prefetch_messages
        channel.prefetch
      end

      # Public: Sets the number of messages prefetched for the messaging channel.
      #
      # If you have more subscriptions to a queue then you need to prefetch more
      # messages so each subscription has something to work on.
      def prefetch_messages=(count)
        channel.prefetch = count
      end


      protected

        # Internal: Connects to the messaging broker.
        #
        # Connects to the broker along with setting up the main channel and exchange for communications.
        def connect_to_broker
          announce "[boot] About to connect..."

          @connection = HotBunnies.connect(connection_options)

          @channel = @connection.create_channel
          @channel.prefetch = config.vms.count

          @exchange = @channel.exchange('', :type => :direct, :durable => true)

          announce("[boot] Connected to an AMQP broker at #{@connection.broker_endpoint} using username #{@connection.username}")
        end

        # Internal: Declares the jobs queue with the broker.
        def declare_queues
          raise "Channel is not initialized" unless channel

          @jobs_queue = channel.queue('builds', :durable => true, :exculsive => false)
        end


      private

        def config
          @config ||= Travis::Worker.config.messaging
        end

        def connection_options
          config.slice(HotBunnies::CONNECTION_PROPERTIES)
        end

        def announce(what)
          puts what
        end
    end

  end
end
