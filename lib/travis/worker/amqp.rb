require 'hot_bunnies'

module HotBunnies
  class Queue
    class Subscription
      def cancel
        raise 'Can\'t cancel: the subscriber haven\'t received an OK yet' if !@subscriber || !@subscriber.consumer_tag
        @channel.basic_cancel(@subscriber.consumer_tag)
        # @executor.shutdown_now if @executor && @shut_down_executor
        @executor.shutdown if @executor && @shut_down_executor
      end
    end
  end
end

module Travis
  class Worker
    module Amqp
      autoload :Consumer,  'travis/worker/amqp/consumer'
      autoload :Publisher, 'travis/worker/amqp/publisher'

      class << self
        def connected?
          !!@connection
        end

        def connection
          @connection ||= HotBunnies.connect(Travis::Worker.config.amqp)
        end
        alias :connect :connection

        def disconnect
          if connection
            connection.close if connection.isOpen
            @connection = nil
          end
        end
      end
    end
  end
end
