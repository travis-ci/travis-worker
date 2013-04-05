require 'travis/worker/instance'
require 'travis/worker/virtual_machine_pool'

module Travis
  module Worker
    class WorkerNotFound < Exception
      def initialize(name)
        super "Unknown worker #{name}"
      end
    end

    class Pool
      def self.create(broker_connection)
        new(Travis::Worker.config.names, Travis::Worker.config, broker_connection, Travis::Worker::VirtualMachinePool.new)
      end

      attr_reader :names, :config, :broker_connection, :vm_pool

      def initialize(names, config, broker_connection, vm_pool)
        @names  = names
        @config = config
        @broker_connection = broker_connection
        @vm_pool = vm_pool
      end

      def start(names)
        each_worker(names) { |worker| worker.start; sleep 5 }
      end

      def stop(names, options = {})
        each_worker(names) { |worker| worker.stop(options) }
      end

      def status
        workers.map { |worker| worker.report }
      end

      def each_worker(names = [])
        names = self.names if names.empty?
        names.each { |name| yield worker(name) }
      end

      def workers
        @workers ||= names.map { |name| Worker::Instance.create(name, vm_pool, config, broker_connection) }
      end

      def worker(name)
        workers.detect { |worker| (worker.name == name) } || raise(WorkerNotFound.new(name))
      end
    end
  end
end
