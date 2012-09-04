module Travis
  class Worker
    module Reporters
      # Reporter that streams build logs. Because workers now support multiple types of
      # projects (e.g. Ruby, Clojure) as long as VMs provide all the necessary, log streaming
      # picks routing key dynamically for each build.
      class LogStreamer
        include Logging, Travis::Serialization

        log_header { "#{name}:log_streamer" }

        attr_reader :name

        def initialize(name, channel, routing_key)
          @name        = name
          @channel     = channel
          @routing_key = routing_key
          @exchange    = @channel.exchange('reporting', :type => :topic, :durable => true)
        end

        def notify(event, data)
          message(event, data)
        end

        def message(event, data)
          data = encode(data.merge(:uuid => Travis.uuid))
          options = {
            :properties => { :type => event },
            :routing_key => @routing_key
          }
          @exchange.publish(data, options)
        end
        # log :message, :as => :debug, :only => :before
        # this has been disabled as logging is also logged as debug, making the
        # logs super verbose, this can be turned on as needed
      end
    end
  end
end
