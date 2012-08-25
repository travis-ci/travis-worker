require "multi_json"

module Travis
  class Worker
    module Reporters
      # Reporter that reports worker state. Each worker has one instance throughout
      # application lifetime.
      class StateReporter
        include Logging, Travis::Serialization

        log_header { "#{name}:state_reporter" }

        attr_reader :name, :exchange

        def initialize(name, channel)
          @name     = name
          @channel  = channel
          @exchange = channel.default_exchange
          @target_queue_name = 'reporting.workers'

          declare_queues
        end

        def notify(event, data)
          message(event, data)
        end

        def message(event, data)
          data = encode(data.merge(:uuid => Travis.uuid))
          options = {
            :properties => { :type => event },
            :routing_key => @target_queue_name
          }
          @exchange.publish(data, options)
        end
        log :message, :as => :debug

        def declare_queues
          @channel.queue(@target_queue_name, :durable => true)
        end
      end
    end
  end
end
