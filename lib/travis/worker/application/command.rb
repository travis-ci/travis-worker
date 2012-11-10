require 'hashr'
require 'json'
require 'travis/worker/utils/serialization'

module Travis
  module Worker
    class Application
      class Command < Hashr
        include Utils::Serialization

        class << self
          def subscribe(subscriber, config, channel)
            queue     = channel.queue("worker.commands.#{config.name}", :durable => true)
            @consumer = queue.subscribe do |message, payload|
              new(subscriber, channel, message, payload).process
            end
          end

          def shutdown
            # may be nil in some scenarios with mocks
            if @consumer
              @consumer.cancel
              @consumer.shutdown!
            end
          end
        end

        attr_reader :target, :command, :message

        def initialize(target, channel, message, payload)
          super(decode(payload))
          @target  = target
          @channel = channel
          @message = message
          @command = delete(:command)
        end

        def process
          reply(target.send(command, *args))
        rescue Exception => e
          puts e.message, e.backtrace
        end

        def output(output)
          reply(output)
        end

        def reply(result)
          # TODO: switch to server-named queues for replies. MK.
          @channel.default_exchange.publish(result, :correlation_id => correlation_id, :routing_key => "replies")
        end

        def args
          empty? ? [] : [self]
        end

        def correlation_id
          message.properties.message_id
        end
      end
    end
  end
end
