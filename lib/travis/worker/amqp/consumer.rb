require 'hot_bunnies'
require 'hashr'

module Travis
  class Worker
    module Amqp
      class Consumer
        class << self
          def builds
            new(Travis::Worker.config.queue)
          end

          def commands
            new("worker.commands.#{Travis::Worker.name}")
          end

          def replies
            new('replies') # TODO can't create a queue worker.replies?
          end
        end

        include Logging

        DEFAULTS = {
          :subscribe => { :ack => false, :blocking => false },
          :queue     => { :durable => true, :exclusive => false },
          :channel   => { :prefetch => 1 }
        }

        attr_reader :name, :options, :subscription

        def initialize(name, options = {})
          @name    = name
          @options = Hashr.new(DEFAULTS.deep_merge(options))
        end

        def subscribe(options = {}, &block)
          options = deep_merge(self.options.subscribe, options)
          debug "subscribing to #{name.inspect} with #{options.inspect}"
          @subscription = queue.subscribe(options, &block)
        end

        def unsubscribe
          debug "unsubscribing from #{name.inspect}"
          subscription.cancel if subscription.try(:active?)
        end

        protected

          def queue
            @queue ||= channel.queue(name, options.queue)
          end

          def channel
            @channel ||= Amqp.connection.create_channel.tap do |channel|
              channel.prefetch = options.channel.prefetch
            end
          end

          def deep_merge(hash, other)
            hash.merge(other, &(merger = proc { |key, v1, v2| Hash === v1 && Hash === v2 ? v1.merge(v2, &merger) : v2 }))
          end
      end
    end
  end
end
