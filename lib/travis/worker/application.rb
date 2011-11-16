require 'hot_bunnies'
require 'hashr'
require 'json'
require 'multi_json'

module Travis
  module Worker
    class Application
      include Util::Logging

      def boot(workers = [])
        install_signal_traps
        manager.start(workers)
        consume_commands
      end

      def start(workers)
        request(:start, :workers => workers)
      end

      def stop(workers, options)
        request(:stop, options.merge(:workers => workers))
      end

      def terminate(options)
        request(:terminate, options)
      end

      def status
        request(:status)
      end

      protected

        def manager
          @manager ||= Manager.create
        end

        def logger
          @logger ||= Logger.new('app')
        end

        def consume_commands
          Amqp::Consumer.commands(logger).subscribe(:ack => false, :blocking => false, &method(:process))
        end

        def process(message, payload)
          log "processing #{payload}"
          payload = MultiJson.decode(payload)
          result = manager.send(payload.delete('command'), payload)
          reply(message, result)
        rescue Exception => e
          puts e.message, e.backtrace
        end

        def reply(message, result)
          Amqp::Publisher.replies.publish(MultiJson.encode(result), :correlation_id => message.properties.message_id)
        end

        def request(command, options = {})
          Amqp::Publisher.commands.publish(options.merge(:command => command), :reply_to => 'replies')
          Amqp::Consumer.replies(logger).subscribe do |message, payload|
            Amqp.disconnect
            return Hashr.new(MultiJson.decode(payload))
          end
        end
        log :request

        def install_signal_traps
          Signal.trap('INT')  { manager.quit }
          Signal.trap('TERM') { manager.quit }
        end
        log :install_signal_traps
    end
  end
end
