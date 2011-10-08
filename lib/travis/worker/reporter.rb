module Travis
  module Worker
    class Reporter

      ROUTING_KEY = 'reporting.jobs'

      attr_reader :messaging_hub

      def initialize
        @messaging_hub = Messaging.hub(ROUTING_KEY)
      end

      def notify(event)
        message(event.type, event.data)
      end

      protected

        def message(type, data)
          messaging_hub.publish(data, :type => type.to_s, :routing_key => ROUTING_KEY)
        end
    end
  end
end
