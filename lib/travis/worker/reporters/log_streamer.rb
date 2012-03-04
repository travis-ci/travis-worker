module Travis
  class Worker
    module Reporters
      # Reporter that streams build logs. Because workers now support multiple types of
      # projects (e.g. Ruby, Clojure) as long as VMs provide all the necessary, log streaming
      # picks routing key dynamically for each build.
      class LogStreamer
        include Logging, Travis::Serialization

        log_header { "reporter:#{name}" }

        attr_reader :name

        def initialize(name, channel, routing_key)
          @name        = name
          @channel     = channel
          # routing_key
          @routing_key = routing_key

          @exchange    = @channel.exchange("reporting", :type => :topic, :durable => true)
        end

        def notify(event, data)
          message(event, data)
        end

        def message(event, data)
          @exchange.publish(encode(data), :properties => { :type => event }, :routing_key => @routing_key)
        end
        log :message, :as => :debug
      end
    end
  end
end
