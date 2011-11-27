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

      def stop(workers, payload)
        request(:stop, payload.merge(:workers => workers))
      end

      def reboot(payload)
        request(:reboot, payload, :reply => false)
      end

      def terminate(payload)
        request(:terminate, payload, :reply => false)
      end

      def status
        request(:status)
      end

      def config
        request(:config)
      end

      def set(payload)
        request(:set, payload)
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
          result = manager.send(payload.delete(:command), *(payload.empty? ? [] : [payload]))
          reply(message, result)
        rescue Exception => e
          puts e.message, e.backtrace
        end

        def reply(message, result)
          Amqp::Publisher.replies.publish(MultiJson.encode(result), :correlation_id => message.properties.message_id)
        end

        def request(command, payload = {}, options = { :reply => true})
          Amqp::Publisher.commands.publish(payload.merge(:command => command), :reply_to => 'replies')

          @timeout = Thread.new do
            sleep(1)
            puts 'Timed out after 5 seconds without any reply'
            # TODO why does this not work?
            # Amqp::Publisher.commands.unsubscribe
            # sleep(0.5)
            # Amqp.disconnect
            java.lang.System.exit(0)
          end

          # TODO why does this not work? throws https://gist.github.com/f5c2c338cab1eeb6c59b
          # Amqp::Consumer.replies.subscribe(:blocking => true, &method(:handle_reply)) if options[:reply]

          Amqp::Consumer.replies.subscribe(:blocking => true) do |message, payload|
            @timeout.kill
            Amqp.disconnect
            return MultiJson.decode(payload)
          end if options[:reply]
        end
        log :request, :as => :debug

        # def handle_reply(message, payload)
        #   @timeout.kill
        #   Amqp.disconnect
        #   MultiJson.decode(payload)
        # end

        def install_signal_traps
          Signal.trap('INT')  { manager.quit }
          Signal.trap('TERM') { manager.quit }
        end
    end
  end
end
