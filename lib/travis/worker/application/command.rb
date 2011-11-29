require 'hashr'
require 'json'
require 'multi_json'

module Travis
  class Worker
    class Application
      class Command < Hashr
        class << self
          def subscribe(subscriber)
            Amqp::Consumer.commands.subscribe do |message, payload|
              new(subscriber, message, payload).process
            end
          end
        end

        attr_reader :target, :command, :message

        def initialize(target, message, payload)
          super(MultiJson.decode(payload))
          @target  = target
          @message = message
          @command = delete(:command)
        end

        def process
          reply(target.send(command, *args)) # , &method(:reply)
        rescue Exception => e
          puts e.message, e.backtrace
        end

        def output(output)
           reply(output)
        end

        def reply(result)
          replies.publish(MultiJson.encode(result), :correlation_id => correlation_id)
        end

        def replies
          Amqp::Publisher.replies
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
