require 'hot_bunnies'

module Travis
  module Worker
    module Amqp
      autoload :Exchange, 'travis/worker/amqp/exchange'
      autoload :Queue,    'travis/worker/amqp/queue'

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
            connection.close
            @connection = nil
          end
        end
      end
    end
  end
end
