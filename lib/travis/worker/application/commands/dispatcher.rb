require 'hashr'
require 'json'
require 'multi_json'
require 'hot_bunnies'
require 'travis/support'
require 'travis/worker/application/commands/cancel_job'

module Travis
  module Worker
    class Application
      module Commands
        class Dispatcher
          include Logging

          attr_reader :pool

          def initialize(pool)
            @pool = pool
          end

          def start
            info "Starting Commands Subscriber"

            channel = Travis::Amqp.connection.create_channel
            channel.prefetch = 1

            exchange = channel.fanout("worker.commands")

            queue = channel.queue("", :exclusive => true)
            queue.bind(exchange)

            @consumer = queue.subscribe(ack: true) do |message, payload|
              process_command(payload)
              message.ack
            end
          end

          def shutdown
            # may be nil in some scenarios with mocks
            if @consumer
              @consumer.cancel
              @consumer.shutdown!
            end
          end

          def process_command(payload)
            decoded = decoded_payload(payload)
            case decoded["type"]
            when "cancel_job"
              info "cancel job message received for job id:#{decoded["job_id"]}, source:#{decoded["source"]}"
              Commands::CancelJob.new(pool, decoded["job_id"]).run
            when nil
              warn "type not present"
            else
              warn "type:#{decoded["type"]} not recognized"
            end
            # reply(target.send(command, *args))
          rescue Exception => e
            puts e.message, e.backtrace
          end

          private

          def decoded_payload(payload)
            MultiJson.decode(payload)
          rescue => e
            error "boom!"
            error e.inspect, e.backtrace
            nil
          end

        end
      end
    end
  end
end
