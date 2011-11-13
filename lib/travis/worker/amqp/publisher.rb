require 'hot_bunnies'
require 'multi_json'

module Travis
  module Worker
    module Amqp
      class Publisher
        class << self
          def commands
            @commands ||= new('worker.commands')
          end

          def reporting
            @reporting ||= new('reporting.jobs')
          end
        end

        attr_reader :routing_key

        def initialize(routing_key)
          @routing_key = routing_key
        end

        def publish(data, options = {})
          data = MultiJson.encode(data) if data.is_a?(Hash)
          options = options.merge(:routing_key => name)
          exchange.publish(data, options)
        end

        protected

          def exchange
            @exchange ||= channel.default_exchange
          end

          def channel
            @channel ||= Amqp.connection.create_channel
          end
      end
    end
  end
end
