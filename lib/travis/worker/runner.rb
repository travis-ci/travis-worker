module Travis
  module Worker

    class Runner

      attr_reader :payload, :job

      def initialize(metadata, payload, reporter)
        @payload  = payload.deep_symbolize_keys
        @metadata = metadata
        @job      = job_type.new(payload)

        job.observers << reporter
      rescue VmNotFound, Errno::ECONNREFUSED
        requeue
        raise $!
      end

      def work!
        job.work!
        Travis::Worker.discard_shell!
      rescue
        announce("#{$!.class.name}: #{$!.message}", $@)
      end

      def job_type
        payload.key?(:build) && payload[:build].key?(:config) ? Job::Build : Job::Config
      end

      def requeue
        announce("#{$!.class.name}: #{$!.message}", $@)
        announce('Can not connect to VM. Stopping job processing ...')
        @metadata.reject(:requeue => true)
      end

      def announce(*what)
        puts what
      end

    end
  end
end
