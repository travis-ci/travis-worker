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

        def initialize(name, state_channel, log_channel)
          @name        = name
          @state_exchange = state_channel.exchange('reporting', :type => :topic, :durable => true)
          @log_exchange   = log_channel.exchange('reporting',   :type => :topic, :durable => true)
        end

        def notify(event, data)
          message(event, data)
        end

        def message(event, data)
          data = encode(data.merge(:uuid => Travis.uuid))
          options = {
            :properties => { :type => event },
            :routing_key => routing_key_for(event)
          }
          exchange_for(event).publish(data, options)
        end
        # log :message, :as => :debug, :only => :before
        # this has been disabled as logging is also logged as debug, making the
        # logs super verbose, this can be turned on as needed
        
        def routing_key_for(event)
          event.to_s =~ /log/ ? 'reporting.jobs.logs' : 'reporting.jobs.builds'
        end

        def exchange_for(event)
          event.to_s =~ /log/ ? @log_exchange : @state_exchange
        end
        
        def close
          @state_exchange.channel.close
          @log_exchange.channel.close
        end
      end
    end
  end
end
