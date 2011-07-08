module Travis
  module Worker
    module Workers

      class Amqp

        #
        # API
        #

        attr_reader :payload, :job, :reporter

        def initialize(metadata, payload)
          @payload  = payload.deep_symbolize_keys
          @metadata = metadata
          @job      = job_type.new(payload)
          # TODO
          @reporter = Reporter::Amqp.new(job.build)
          job.observers << reporter
        rescue VmNotFound, Errno::ECONNREFUSED
          puts "#{$!.class.name}: #{$!.message}", $@
          puts 'Can not connect to VM. Stopping job processing ...'
          stop_processing
          requeue
          raise $!
        end

        def work!
          # reporter.deliver_messages!
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
          # TBD
        end

        def requeue
          @metadata.reject :requeue => true
        end

      end # Amqp
    end # Workers
  end # Worker
end # Travis
