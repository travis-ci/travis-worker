module Travis
  module Worker
    module Workers

      class Base

        #
        # API
        #

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
          raise NotImplementedError
        end

        def requeue
          raise NotImplementedError
        end

      end # Base
    end # Workers
  end # Worker
end # Travis
