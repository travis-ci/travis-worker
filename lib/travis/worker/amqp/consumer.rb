require 'hot_bunnies'

module Travis
  module Worker
    module Amqp
      class Consumer
        class << self
          def builds
            new(Travis::Worker.config.queue)
          end

          def commands
            new('worker.commands')
          end
        end

        attr_reader :name

        def initialize(name)
          @name = name
        end

        def subscribe(options = {}, &block)
          queue.subscribe(options, &block)
        end

        protected

          def queue
            @queue ||= channel.queue(name, :durable => true, :exclusive => false)
          end

          def channel
            @channel ||= Amqp.connection.create_channel.tap do |channel|
              channel.prefetch = 1
            end
          end
      end
    end
  end
end
