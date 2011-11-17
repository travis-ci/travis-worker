require 'hot_bunnies'
require 'multi_json'
require 'hashr'

module Travis
  module Worker
    module Amqp
      class Publisher
        class << self
          def commands
            new("worker.commands.#{Travis::Worker.name}")
          end

          def reporting
            new('reporting.jobs')
          end

          def replies
            new('replies') # TODO can't create a queue worker.replies?
          end
        end

        attr_reader :routing_key, :options

        def initialize(routing_key, options = {})
          @routing_key = routing_key
          @options = options
        end

        def publish(data, options = {})
          data = MultiJson.encode(data) if data.is_a?(Hash)
          defaults = { :routing_key => routing_key, :properties => { :message_id => rand(100000000000).to_s } }
          exchange.publish(data, deep_merge(defaults, options))
        end

        protected

          def exchange
            @exchange ||= channel.default_exchange
          end

          def channel
            @channel ||= Amqp.connection.create_channel
          end

          def deep_merge(hash, other)
            hash.merge(other, &(merger = proc { |key, v1, v2| Hash === v1 && Hash === v2 ? v1.merge(v2, &merger) : v2 }))
          end
      end
    end
  end
end
