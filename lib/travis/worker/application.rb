require 'hot_bunnies'
require 'hashr'
require 'json'
require 'multi_json'

module Travis
  module Worker
    class Application
      include Logging

      def boot(workers = [])
        setup
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

        def setup
          Travis.logger.level = Logger.const_get(Travis::Worker.config.log_level.to_s.upcase) # TODO hrmm ...
        end

        def manager
          @manager ||= Manager.create
        end

        def consume_commands
          Amqp::Consumer.commands.subscribe(&method(:process))
        end

        def process(message, payload)
          info "processing #{payload}"
          payload = Hashr.new(MultiJson.decode(payload))
          result = manager.send(payload.delete(:command), payload)
          reply(message, result)
        rescue Exception => e
          puts e.message, e.backtrace
        end

        def reply(message, result)
          Amqp::Publisher.replies.publish(MultiJson.encode(result), :correlation_id => message.properties.message_id)
        end

        def request(command, options = {})
          Amqp::Publisher.commands.publish(options.merge(:command => command), :reply_to => 'replies')
          Amqp::Consumer.replies.subscribe(:blocking => true) do |message, payload|
            Amqp.disconnect
            return MultiJson.decode(payload)
          end
        end
        log :request

        def install_signal_traps
          Signal.trap('INT')  { manager.quit }
          Signal.trap('TERM') { manager.quit }
        end
    end
  end
end
