require 'travis/support/logging'
require 'travis/worker/utils/serialization'

module Travis
  module Worker
    # Reporter that streams build logs. Because workers now support multiple types of
    # projects (e.g. Ruby, Clojure) as long as VMs provide all the necessary, log streaming
    # picks routing key dynamically for each build.
    class Reporter
      include Logging
      include Utils::Serialization

      log_header { "#{name}:log_streamer" }

      attr_reader :name

      def initialize(name, state_channel, log_channel)
        @name = name

        @state_exchange = state_channel.exchange('reporting', type: :topic, durable: true)
        @log_exchange   = log_channel.exchange('reporting',   type: :topic, durable: true)

        @logs_part_number = 0
      end

      def notify(event, data)
        message(event, data)
      end

      def message(event, data)
        data = encode(data.merge(uuid: Travis.uuid))
        options = {
          properties: { type: event },
          routing_key: routing_key_for(event)
        }
        exchange_for(event).publish(data, options)
      end
      # log :message, :as => :debug, :only => :before
      # this has been disabled as logging is also logged as debug, making the
      # logs super verbose, this can be turned on as needed

      def routing_key_for(event)
        event.to_s =~ /log/ ? Travis::Worker.config.logging_channel : 'reporting.jobs.builds'
      end

      def exchange_for(event)
        event.to_s =~ /log/ ? @log_exchange : @state_exchange
      end

      def close
        @state_exchange.channel.close
        @log_exchange.channel.close
      end

      # simple helpers
      def send_log(job_id, output, last_message = false)
        @logs_part_number += 1
        message = { id: job_id, log: output, number: @logs_part_number }
        message[:final] = true if last_message
        notify('job:test:log', message)
      end

      def send_last_log(job_id)
        send_log(job_id, "", true)
      end

      def notify_job_started(job_id)
        notify('job:test:start',  id: job_id, state: 'started', started_at: Time.now.utc)
      end

      def notify_job_finished(job_id, result)
        notify('job:test:finish', id: job_id, state: normalized_state(result), finished_at: Time.now.utc)
      end

      def restart(job_id)
        notify('job:test:reset', id: job_id, state: 'reset')
      end

      def normalized_state(result)
        case result
        when 0; 'passed'
        when 1; 'failed'
        when 2; 'errored'
        else    'errored'
        end
      end
    end
  end
end
