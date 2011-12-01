module Travis
  class Worker
    class Factory
      attr_reader :name

      def initialize(name, config = nil)
        @name = name
        @config = config
      end

      def worker
        Worker.new(name, vm, queues, reporter, config)
      end

      def vm
        VirtualMachine::VirtualBox.new(name)
      end

      def queues
        [Amqp::Consumer.configure, Amqp::Consumer.builds]
      end

      def reporter
        Reporter.new(name, Amqp::Publisher.jobs, Amqp::Publisher.workers)
      end

      def config
        @config ||= Travis::Worker.config
      end
    end
  end
end
