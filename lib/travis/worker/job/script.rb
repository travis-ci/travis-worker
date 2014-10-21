require "faraday"
require "json"
require "travis/build"
require "metriks"

module Travis
  module Worker
    module Job
      class Script
        CompileError = Class.new(StandardError)

        include Logging
        include Retryable

        log_header { "#{@log_prefix}:worker:job:script" }

        def initialize(payload, log_prefix)
          @payload = payload
          @log_prefix = log_prefix
        end

        def script
          if Travis::Worker.config[:build][:url]
            info "fetching script from API"
            fetch_from_api
          else
            info "generating build script"
            generate_using_build
          end
        end

        private

        def fetch_from_api
          response = retryable(tries: 3, on: Faraday::Error::TimeoutError) do
            Metriks.timer("worker.job.script.api").time do
              connection.post("/script", JSON.dump(data), {
                "Content-Type" => "application/json",
                "Accept" => "text/plain",
              })
            end
          end

          if response.status == 500
            raise_compile_error_with_message response.body
          end

          response.body
        rescue Faraday::Error::TimeoutError
          raise CompileError, "The build script API timed out"
        end

        def generate_using_build
          Metriks.timer("worker.job.script.build").time do
            Travis::Build.script(data).compile
          end
        rescue => e
          raise_compile_error_with_message e.message
        end

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
            skip_etc_hosts_fix: Travis::Worker.config[:skip_etc_hosts_fix],
            cache_options: Travis::Worker.config[:cache_options]
          )
        end

        def raise_compile_error_with_message(msg='')
          raise CompileError, "An error occurred while compiling the build script: #{msg}\n\nTest your configuration file with http://lint.travis-ci.org."
        end
      end
    end
  end
end
