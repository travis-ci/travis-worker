require 'celluloid'
require 'travis/support/logging'
require 'travis/worker/utils/hard_timeout'
require 'travis/worker/job/script'

# monkey patch net-ssh for now
require 'net/ssh/buffered_io'
module Net
  module SSH
    module BufferedIo
      def fill(n=8192)
        input.consume!
        data = recv(n)
        debug { "read #{data.length} bytes" }
        input.append(data) if data
        return data ? data.length : 0
      end
    end
  end
end


module Travis
  module Worker
    module Job
      class Runner
        include Logging
        # include Celluloid
        include Retryable

        class ConnectionError < StandardError; end

        attr_reader :payload, :session, :reporter, :host_name, :timeouts, :log_prefix

        log_header { "#{log_prefix}:worker:job:runner" }

        def initialize(payload, session, reporter, host_name, timeouts, log_prefix)
          @payload  = payload
          @session  = session
          @reporter = reporter
          @host_name  = host_name
          @timeouts   = Hashr.new(timeouts)
          @log_prefix = log_prefix
        end

        def run
          if check_config
            setup
            start
            stop
          end
        end

        def compile_script
          Script.new(payload, @log_prefix).script
        end

        def setup_log_streaming
          session.log_silence_timeout = timeouts.log_silence
          session.on_output do |output, options|
            announce(output)
          end
        end

        def setup
          setup_log_streaming
          start_session
        rescue Net::SSH::AuthenticationFailed, Errno::ECONNREFUSED, Timeout::Error => e
          log_exception(e)
          connection_error
        end
        log :setup, as: :debug

        def start
          notify_job_started

          upload_script
          result = run_script
        rescue Ssh::Session::NoOutputReceivedError => e
          unless stop_with_exception(e)
            warn "[Possible VM Error] The job has been requeued as no output has been received and the ssh connection could not be closed"
          end
          result = 'errored'
        rescue Utils::Buffer::OutputLimitExceededError, Script::CompileError => e
          stop_with_exception(e)
          result = 'errored'
        rescue IOError, Errno::ECONNREFUSED
          connection_error
        ensure
          if @canceled
            sleep 2
            reporter.send_log(job_id, "\n\nDone: Job Cancelled\n")
            result = 'canceled'
          end
          notify_job_finished(result) if result
        end

        def stop
          exit_exec!
          sleep 2
          session.close
        end

        def cancel
          @canceled = true
          stop
          # need to mark job as canceled
        end

        def check_config
          case payload["config"][:".result"]
          when "parse_error"
            announce "\033[31;1mERROR\033[0m: An error occurred while trying to parse your .travis.yml file.\n"
            announce "  http://lint.travis-ci.org can check your .travis.yml.\n"
            announce "  Please make sure that the file is valid YAML.\n\n"
            # TODO: Remove all of this once we can actually error the build
            #   before it gets to the worker
            notify_job_started
            sleep 4
            notify_job_finished(nil)
            return false
          when "not_found"
            announce "\033[33;1mWARNING\033[0m: We were unable to find a .travis.yml file. This may not be what you\n"
            announce "  want. Build will be run with default settings.\n\n"
          end

          true
        end

        def upload_script
          Timeout::timeout(15) do
            info "making sure build.sh doesn't exist"
            if session.exec("test -f ~/build.sh") == 0
              warn "Reused VM with leftover data, requeueing"
              connection_error
            end

            info "uploading build.sh"
            session.upload_file("~/build.sh", payload['script'] || compile_script)

            info "setting +x permission on build.sh"
            session.exec("chmod +x ~/build.sh")
          end
        rescue Timeout::Error
          connection_error
        end

        def run_script
          info "running the build"
          Timeout::timeout(timeouts.hard_limit) do
            if session.config.platform == :osx
              session.upload_file("~/wrapper.sh", <<EOF)
#!/bin/bash

[[ -f ~/build.sh.exit ]] && rm ~/build.sh.exit

until nc 127.0.0.1 15782; do sleep 1; done

until [[ -f ~/build.sh.exit ]]; do sleep 1; done
exit $(cat ~/build.sh.exit)
EOF
              session.exec("bash ~/wrapper.sh") { exit_exec? }
            else
              session.exec("bash --login ~/build.sh") { exit_exec? }
            end
          end
        rescue Timeout::Error
          timedout
          'errored'
        end

        def start_session
          announce("Using worker: #{host_name}\n\n")
          retryable(:tries => 5, :sleep => 3) do
            Timeout.timeout(10) do
              session.connect
            end
          end
        end
        log :start_session, as: :debug

        def job_id
          payload['job']['id']
        end

        def announce(message)
          reporter.send_log(job_id, message)
        end

        def timedout
          stop
          minutes = timeouts.hard_limit / 60.0
          announce("\n\nYour test run exceeded #{minutes.to_i} minutes. \n\nOne possible solution is to split up your test run.")
          error "the job (slug:#{self.payload['repository']['slug']} id:#{self.payload['job']['id']}) took more than #{minutes} minutes and was cancelled"
        end

        private

        def exit_exec?
          @exit_exec || false
        end

        def exit_exec!
          @exit_exec = true
        end

        def notify_job_started
          reporter.notify_job_started(job_id)
        end

        def notify_job_finished(result)
          reporter.send_last_log(job_id)
          reporter.notify_job_finished(job_id, result)
        end

        def connection_error
          announce("There was an error with the connection to the VM.\n\nYour job will be requeued shortly.")
          raise ConnectionError
        end

        def stop_with_exception(exception)
          warn "build error : #{exception.class}, #{exception.message}"
          warn "  #{exception.backtrace.join("\n  ")}"
          stopped = stop
          announce("\n\n#{exception.message}\n\n")

          stopped
        end
      end
    end
  end
end
