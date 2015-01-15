require 'multi_json'
require 'time'
require 'excon'

module Travis
  module Worker
    class Application
      class HTTPHeartbeat
        include Celluloid

        attr_reader :url, :shutdown_block, :interval

        def initialize(url, &shutdown_block)
          @url, @shutdown_block = url, shutdown_block
          @interval = Travis::Worker.config.heartbeat.interval
          conn
        end

        def start
          @timer = every(interval) { beat }
        end

        def stop
          @timer.cancel if @timer
        end

        def beat
          shutdown_block.call if expected_state == :down
        end

        private

        def expected_state
          raw_response.fetch('expected_state', 'up').to_sym
        end

        def raw_response
          response = conn.post(headers: {'Date' => Time.now.utc.httpdate})
          MultiJson.decode(conn.post.data[:body])
        end

        def conn
          @conn ||= Excon.new(url)
        end
      end
    end
  end
end
