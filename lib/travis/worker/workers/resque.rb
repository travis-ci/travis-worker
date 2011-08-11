module Travis
  module Worker
    module Workers
      # Main worker dispatcher class that get's instantiated by Resque. Once we get rid of
      # Resque this class can take over the responsibility of popping jobs from the queue.
      #
      # The Worker instantiates jobs (currently based on the payload, should be based on
      # the queue) and runs them.
      class Resque < Base

        #
        # API
        #

        def stop_processing
          Process.kill('USR2', Process.ppid)
        end

        def requeue
          Travis::Worker.class_eval { @queue = 'builds' }
          ::Resque.enqueue(Travis::Worker, payload)
        end # requeue
      end # Resque
    end # Workers
  end # Worker
end # Travis
