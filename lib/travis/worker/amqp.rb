require 'hot_bunnies'
require 'multi_json'


module Travis
  module Worker
    class Amqp
      class << self
        def builds
          @builds ||= new(Travis::Worker.config.queue)
        end

        def commands
          @commands ||= new('workers.commands')
        end

        def reporting
          @reporting ||= new('reporting.jobs')
        end

        def connected?
          !!@connection
        end

        def connection
          @connection ||= HotBunnies.connect(Travis::Worker.config.amqp)
        end
        alias :connect :connection

        def disconnect
          if connection
            connection.close
            @connection = nil
          end
        end
      end

      attr_reader :name

      def initialize(name)
        @name = name
      end

      def publish(data, options = {})
        data = MultiJson.encode(data) if data.is_a?(Hash)
        options = options.merge(:routing_key => name)
        exchange.publish(data, options)
      end

      def subscribe(options = {}, &block)
        queue.subscribe(options, &block)
      end

      protected

        def exchange
          @exchange ||= channel.default_exchange
        end

        def queue
          @queue ||= channel.queue(name, :durable => true, :exclusive => false)
        end

        def channel
          @channel ||= self.class.connection.create_channel.tap do |channel|
            channel.prefetch = 1
          end
        end
    end
  end
end
