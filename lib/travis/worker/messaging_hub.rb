require 'hot_bunnies'

module Travis
  module Worker

    # Represents a connection to the Travis messaging broker.
    #
    # The connection, main channel and exchange, and jobs queue are all
    # encapsulated and available from this class.
    class MessagingHub

      # Public: Returns the messaging connection.
      attr_reader :connection

      # Public: Returns the channel for messaging communications.
      attr_reader :channel

      # Public: Returns the exchange for messaging communications.
      attr_reader :exchange

      # Public: Returns the jobs queue where jobs are published to.
      attr_reader :jobs_queue

      # Initialize a MessagingConnection
      #
      # configuration - A Config to use for connection details (default: nil)
      def initialize(configuration = nil)
        @connection = @channel = @exchange = @jobs_queue = nil

        config(configuration)
      end

      # Connects to the messaging broker.
      #
      # Along with connecting to the broker, queues are declared and setup.
      #
      # Returns self
      def bind
        connect_to_broker

        declare_queues

        self
      rescue Java::ComRabbitmqClient::PossibleAuthenticationFailureException => e
        announce("Failed to authenticate with #{connection.address.to_s} on port #{connection.port}")
      rescue Java::JavaIo::IOException => e
        announce("Failed to connect with config options #{config.inspect}")
      end

      # Closes the connection to the messaging broker.
      #
      # As well as disconnecting from the messaging broker, all related connections to the jobs queue,
      # exchange and channel are also deleted or closed.
      def unbind
        announce("Closing connection to broker...")

        jobs_queue.delete
        channel.close
        connection.close

        announce("Connection to broker closed")
      end

      # Sets the number of messages prefetched for the messaging channel.
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
          announce "About to connect..."

          @connection = HotBunnies.connect(config.messaging)

          @channel = @connection.create_channel
          @channel.prefetch = 1

          @exchange = @channel.exchange('', :type => :direct, :durable => true)

          announce("Connected to an AMQP broker at #{connection.address}:#{connection.port}")
        end

        # Internal: Declares the jobs queue with the broker.
        def declare_queues
          raise "Channel is not initialized" unless channel

          @jobs_queue = channel.queue('builds', :durable => true, :exculsive => false)
        end


      private

        def config(configuration = nil)
          @config ||= configuration || Travis::Worker.config
          @config
        end

        def announce(what)
          puts "[messaging] #{what}"
        end
    end

  end
end
