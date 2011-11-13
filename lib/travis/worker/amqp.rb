require 'hot_bunnies'

module Travis
  module Worker
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
            connection.close
            @connection = nil
          end
        end
      end
    end
  end
end
