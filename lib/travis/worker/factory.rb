module Travis
  class Worker
    class Factory
      attr_reader :name

      def initialize(name, config = nil)
        @name = name
        @config = config
      end

      def worker
        Worker.new(name, vm, queue_names, reporter, config)
      end

      def vm
        VirtualMachine::VirtualBox.new("travis-#{name}")
      end

      def queue_names
        %w(builds.configure) + Array(@config[:queues] || @config[:queue] || [])
      end

      def reporter
        Reporter.new(name, Amqp::Publisher.jobs(config.queue), Amqp::Publisher.workers)
      end

      def config
        @config ||= Travis::Worker.config
      end
    end
  end
end
