require 'hot_bunnies'
require 'multi_json'

module Travis
  module Worker

    module Messaging
      class << self
        extend Util::Logging

        def connection
          @connection ||= begin
            conn = HotBunnies.connect(config)
          rescue Java::ComRabbitmqClient::PossibleAuthenticationFailureException => e
            announce("Failed to authenticate with #{conn.address.to_s} on port #{conn.port}")
          rescue Java::JavaIo::IOException => e
            announce("Failed to connect with config options #{config.inspect}")
          end
        end

        def connect
          connection
        end

        def disconnect
          if connection
            connection.close
            @connection = nil
          end
        end

        def declare_queues(*queue_names)
          channel = connection.create_channel

          queue_names.each do |queue_name|
            channel.queue(queue_name, :durable => true, :exculsive => false)
          end

          channel.close
        end

        def hub(name)
          Hub.new(name, connection)
        end

        def config
          Travis::Worker.config.messaging
        end

        def logging_header
          "messaging"
        end
      end


      class Hub
        attr_reader :name
        attr_reader :connection
        attr_reader :subscription

        def initialize(name, connection)
          @name = name
          @connection = connection
        end

        def publish(data, options = {})
          data = MultiJson.encode(data) if data.is_a?(Hash)
          options = options.merge(:routing_key => name)
          exchange.publish(data, options)
        end

        def subscribe(options = {}, &block)
          queue.subscribe(options, &block)
        end

        def cancel_subscription
          subscription.cancel if subscription
        end

        def close
          cancel_subscription
          channel.close
        end

        protected

          def channel
            @channel ||= begin
              channel = connection.create_channel
              channel.prefetch = 1
              channel
            end
          end

          def exchange
            @exchange ||= channel.default_exchange
          end

          def queue
            @queue ||= channel.queue(name, :durable => true, :exculsive => false)
          end
      end
    end

  end
end