require 'hot_bunnies'
require 'hashr'

module Travis
  module Worker
    module Amqp
      class Consumer
        class << self
          def builds(logger)
            new(Travis::Worker.config.queue, logger)
          end

          def commands(logger)
            new('worker.commands', logger)
          end
        end

        include Util::Logging

        DEFAULTS = {
          :durable   => true,
          :exclusive => false,
          :prefetch  => 1
        }

        attr_reader :name, :options, :logger, :subscription

        def initialize(name, logger, options = {})
          @name    = name
          @logger  = logger
          @options = Hashr.new(DEFAULTS.merge(options))
        end

        def subscribe(options = {}, &block)
          log "subscribing to #{name.inspect} with #{options.inspect}"
          @subscription = queue.subscribe(options, &block)
        end

        def unsubscribe
          log "unsubscribing from #{name.inspect}"
          subscription.cancel if subscription
        end

        protected

          def queue
            @queue ||= channel.queue(name, options)
          end

          def channel
            @channel ||= Amqp.connection.create_channel.tap do |channel|
              channel.prefetch = options.prefetch
            end
          end
      end
    end
  end
end
