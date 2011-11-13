require 'hot_bunnies'
require 'hashr'
require 'json'
require 'multi_json'

module Travis
  module Worker
    class Application
      extend Util::Logging

      def boot(workers = [])
        install_signal_traps
        manager.start(workers)
        subscribe
      end

      def start(workers)
        call_remote(:start, :workers => workers)
      end

      def stop(workers, options)
        call_remote(:stop, options.merge(:workers => workers))
      end

      def terminate(options)
        call_remote(:terminate, options)
      end

      protected

        def subscribe
          Amqp.commands.subscribe(:ack => false, :blocking => false, &method(:process))
        end

        def process(message, payload)
          message.ack
          payload = decode(payload)
          manager.send(payload.delete(:command), payload)
        rescue Exception => e
          puts e.message, e.backtrace
        end

        def manager
          @manager ||= Manager.create
        end

        def logger
          @logger ||= Logger.new('app')
        end

        def install_signal_traps
          Signal.trap('INT')  { manager.quit }
          Signal.trap('TERM') { manager.quit }
        end
        log :install_signal_traps

        def call_remote(command, options)
          Amqp.commands.publish(options.merge(:command => command))
          Amqp.disconnect
        end
        log :call_remote

        def decode(payload)
          Hashr.new(MultiJson.decode(payload), :workers => [])
        end
    end
  end
end
