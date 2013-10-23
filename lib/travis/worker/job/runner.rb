require 'celluloid'
require 'travis/support/logging'
require 'travis/worker/utils/hard_timeout'
require 'travis/build'


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

        class ScriptCompileError < StandardError
          attr_reader :original

          def initialize(msg, original = $!)
            super(msg)
            @original = original
          end
        end

        attr_reader :payload, :session, :reporter, :host_name, :hard_timeout, :log_prefix

        log_header { "#{log_prefix}:worker:job:runner" }

        def initialize(payload, session, reporter, host_name, hard_timeout, log_prefix)
          @payload  = payload
          @session  = session
          @reporter = reporter
          @host_name    = host_name
          @hard_timeout = hard_timeout
          @log_prefix   = log_prefix
        end

        def run
          if check_config
            setup
            start
            stop
          end
        end

        def compile_script
          data = payload.merge(timeouts: false, hosts: Travis::Worker.config[:hosts], cache_options: Travis::Worker.config[:cache_options])
          Build.script(data, logs: { build: false, state: true }).compile
        rescue StandardError => e
          raise ScriptCompileError, "An error occured while compiling the build script : #{e.message}"
        end

        def setup_log_streaming
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

        def start
          result = nil

          notify_job_started

          Timeout::timeout(hard_timeout) do
            result = upload_and_run_script
          end

          result
        rescue Ssh::Session::NoOutputReceivedError => e
          warn "build error : #{e.class}, #{e.message}"
          warn "  #{e.backtrace.join("\n  ")}"
          unless stop
            warn "[Possible VM Error] The job has been requeued as no output has been received and the ssh connection could not be closed"
          end
          announce("\n\n#{e.message}\n\n")
        rescue Utils::Buffer::OutputLimitExceededError, ScriptCompileError => e
          warn "build error : #{e.class}, #{e.message}"
          warn "  #{e.backtrace.join("\n  ")}"
          stop
          announce("\n\n#{e.message}\n\n")
        rescue Timeout::Error => e
          timedout
        rescue IOError, Errno::ECONNREFUSED => e
          connection_error
        ensure
          if @canceled
            sleep 2
            reporter.send_log(job_id, "\n\nDone: Job Cancelled\n")
            result = 'canceled'
          end
          notify_job_finished(result)
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
            announce "\033[31;1mERROR\033[0m: An error occured while trying to parse your .travis.yml file.\n"
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

        def upload_and_run_script
          info "making sure build.sh doesn't exist"
          if session.exec("test -f ~/build.sh") == 0
            warn "Reused VM with leftover data, requeueing"
            connection_error
          end

          info "uploading build.sh"
          session.upload_file("~/build.sh", payload['script'] || compile_script)

          info "setting +x permission on build.sh"
          session.exec("chmod +x ~/build.sh")

          info "running the build"
          session.exec("~/build.sh") { exit_exec? }
        end

        def start_session
          announce("Using worker: #{host_name}\n\n")
          retryable(:tries => 3, :sleep => 3) do
            Timeout.timeout(10) do
              session.connect
            end
          end
        end

        def job_id
          payload['job']['id']
        end

        def announce(message)
          reporter.send_log(job_id, message)
        end

        def timedout
          stop
          minutes = hard_timeout / 60.0
          announce("\n\nI'm sorry but your test run exceeded #{minutes} minutes. \n\nOne possible solution is to split up your test run.")
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
          announce("I'm sorry but there was an error with the connection to the VM.\n\nYour job will be requeued shortly.")
          raise ConnectionError
        end
      end
    end
  end
end
