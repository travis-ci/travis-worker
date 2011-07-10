module Travis
  module Worker
    module Reporter
      class Amqp < Base

        def initialize(build, channel)
          @build    = build
          @channel  = channel
          @exchange = channel.default_exchange
        end

        def finished?
          !active?
        end # finished?

        #
        # Implementation
        #

        protected

        def active?
          # TODO: we actually can check EventMachine's outgoing buffer size
          false
        end

        def message(type, data)
          @exchange.publish(data[:log], :type => type.to_s, :routing_key => "reporting.progress", :arguments => { 'x-incremental' => !!data[:incremental] })
        end
      end # Amqp
    end # Reporter
  end # Worker
end # Travis
