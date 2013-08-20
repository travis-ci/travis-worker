require 'travis/support'

# { "type": "cancel_job", "job_id": 388638 }

module Travis
  module Worker
    class Application
      module Commands
        class CancelJob
          include Logging

          attr_reader :pool, :job_id

          def initialize(pool, job_id)
            @pool = pool
            @job_id = job_id
          end

          def run
            worker = find_worker
            if worker
              info "worker running job id:#{job_id} found, canceling now"
              worker.cancel
            end
          end

          def find_worker
            @pool.workers.detect do |worker|
              if worker.payload
                worker.payload.job.id.to_s == job_id.to_s
              else
                false
              end
            end
          end
        end
      end
    end
  end
end
