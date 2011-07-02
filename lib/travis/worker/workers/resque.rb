module Travis
  module Worker
    module Workers
      # Main worker dispatcher class that get's instantiated by Resque. Once we get rid of
      # Resque this class can take over the responsibility of popping jobs from the queue.
      #
      # The Worker instantiates jobs (currently based on the payload, should be based on
      # the queue) and runs them.
      class Resque
        attr_reader :payload, :job, :reporter

        def initialize(payload)
          @payload  = payload.deep_symbolize_keys
          @job      = job_type.new(payload)
          @reporter = Reporter::Http.new(job.build)
          job.observers << reporter
        rescue VmNotFound, Errno::ECONNREFUSED
          puts "#{$!.class.name}: #{$!.message}", $@
          puts 'Can not connect to VM. Stopping job processing ...'
          stop_processing
          requeue
          raise $!
        end

        def shell
          self.class.shell
        end

        def work!
          reporter.deliver_messages!
          job.work!
        rescue
          puts "#{$!.class.name}: #{$!.message}", $@
        ensure
          sleep(0.1) until reporter.finished?
        end

        def job_type
          payload.key?(:build) && payload[:build].key?(:config) ? Job::Build : Job::Config
        end

        def stop_processing
          Process.kill('USR2', Process.ppid)
        end

        def requeue
          Travis::Worker.class_eval { @queue = 'builds' }
          Resque.enqueue(Travis::Worker, payload)
        end
      end # Resque
    end # Workers
  end # Worker
end # Travis
