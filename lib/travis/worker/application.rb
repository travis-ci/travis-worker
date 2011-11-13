require 'hot_bunnies'
require 'hashr'
require 'json'
require 'multi_json'

module Travis
  module Worker
    import java.util.concurrent.CountDownLatch

    class Application
      extend Util::Logging

      def boot(workers = [])
        @worker_initialization_barrier = CountDownLatch.new(workers.size)

        install_signal_traps
        manager.start(workers)

        # we need to delay starting commands consumer until after all worker consumers are
        # ready. The proper way of doing it would be to use java.util.concurrent.CountDownLatch that we
        # would pass to Manager#start and then Worker#initialize. Then once consumer is registered (we got
        # basic.consume-ok from RabbitMQ) we would countDown on that latch. However, HotBunnies right now
        # does not provide a way of registering basic.consume-ok callback. So we figured we can just wait
        # because nobody will try to stop the worker that was just started in real world scenarios.
        # Per discussion with Sven. MK.
        # sleep(workers.size * 1.5)
        sleep(0.1) until manager.ready?

        consume_commands
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

        def consume_commands
          Amqp::Consumer.commands.subscribe(:ack => false, :blocking => false, &method(:process))
        end

        def process(message, payload)
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
          Amqp::Publisher.commands.publish(options.merge(:command => command))
          Amqp.disconnect
        end
        log :call_remote

        def decode(payload)
          Hashr.new(MultiJson.decode(payload), :workers => [])
        end
    end
  end
end
