module Travis
  class Worker
    class Factory
      attr_reader :name, :config, :broker_connection

      def initialize(name, config = nil, broker_connection = nil)
        @name              = name
        @config            = config
        @broker_connection = broker_connection
      end

      def worker
        Worker.new(name, vm, @broker_connection, queue_names, config)
      end

      def vm
        VirtualMachine::VirtualBox.new(name)
      end

      def queue_names
        Array(@config[:queues] || @config[:queue] || [])
      end

      def config
        @config ||= Travis::Worker.config
      end
    end
  end
end
