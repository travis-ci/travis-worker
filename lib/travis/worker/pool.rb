require 'java'

module Travis
  class WorkerNotFound < Exception
    def initialize(name)
      super "Unknown worker #{name}"
    end
  end

  class Worker
    class Pool
      def self.create
        new(Travis::Worker.names, Travis::Worker.config)
      end

      attr_reader :names, :config

      def initialize(names, config)
        @names  = names
        @config = config
      end

      def start(names)
        each_worker(names) { |worker| worker.start }
      end

      def stop(names, options = {})
        each_worker(names) { |worker| worker.stop(options) }
      end

      def status
        workers.inject({}) { |status, worker| status.merge(worker.name => worker.report) }
      end

      protected

        def each_worker(names)
          names = self.names if names.empty?
          names.each { |name| yield worker(name) }
        end

        def workers
          @workers ||= names.map { |name| Worker.create(name, config) }
        end

        def worker(name)
          workers.detect { |worker| (worker.name == name) } || raise(WorkerNotFound.new(name))
        end
    end
  end
end
