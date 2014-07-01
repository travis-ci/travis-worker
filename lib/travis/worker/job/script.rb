require "faraday"
require "json"

module Travis
  module Worker
    module Job
      class Script
        CompileError = Class.new(StandardError)

        include Retryable

        def initialize(payload)
          @payload = payload
        end

        def script
          response = retryable(tries: 3, on: Faraday::Error::TimeoutError) do
            connection.post("/script", JSON.dump(data), "Content-Type" => "application/json")
          end

          if response.status == 500
            raise CompileError, "An error occurred while compiling the build script: #{response.body}"
          end

          response.body
        rescue Faraday::Error::TimeoutError
          raise CompileError, "The build script API timed out"
        end

        private

        def connection
          @connection ||= Faraday.new(
            url: Travis::Worker.config[:build].fetch(:url),
            headers: {
              "Authorization" => "token #{Travis::Worker.config[:build].fetch(:api_token)}",
              "User-Agent" => "travis-worker",
            },
            timeout: Travis::Worker.config[:timeouts].fetch(:build_script),
          )
        end

        def data
          @payload.merge(
            hosts: Travis::Worker.config[:hosts],
            paranoid: Travis::Worker.config[:paranoid],
            skip_resolv_updates: Travis::Worker.config[:skip_resolv_updates],
            skip_etch_hosts_fix: Travis::Worker.config[:skip_etc_hosts_fix],
            cache_options: Travis::Worker.config[:cache_options]
          )
        end
      end
    end
  end
end
