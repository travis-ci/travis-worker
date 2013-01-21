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
        include Celluloid
        include Retryable
        
        class ConnectionError < StandardError; end

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

        def generate_script
          Build.script(payload.merge(timeouts: false), logs: { build: false, state: true })
        end

        def setup_log_streaming
          session.on_output do |output, options|
            announce(output)
          end
        end

        def setup
          setup_log_streaming
          start_session
        rescue Net::SSH::AuthenticationFailed, Errno::ECONNREFUSED => e
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
        rescue Utils::Buffer::OutputLimitExceededError, Ssh::Session::NoOutputReceivedError => e
          warn "build error : #{e.class}"
          stop
          announce("\n\n#{e.message}\n\n")
        rescue Timeout::Error => e
          timedout
        rescue Errno::ECONNREFUSED => e
          connection_error
        ensure
          notify_job_finished(result)
        end

        def stop
          exit_exec!
          sleep 2
          session.close
        end

        def upload_and_run_script
          info "uploading build.sh"
          session.upload_file("~/build.sh", generate_script.compile)

          info "setting +x permission on build.sh"
          session.exec("chmod +x ~/build.sh")

          info "running the build"
          session.exec("~/build.sh") { exit_exec? }
        end

        def start_session
          announce("Using worker: #{host_name}\n\n")
          retryable(:tries => 3) do
            session.connect
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
          announce("I'm sorry but there was an error connection to the VM.\n\nYour job will be requeued shortly.")
          raise ConnectionError
        end
      end
    end
  end
end