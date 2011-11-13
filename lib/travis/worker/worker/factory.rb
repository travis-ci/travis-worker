module Travis
  module Worker
    class Worker
      class Factory
        attr_reader :name

        def initialize(name, config = nil)
          @name = name
          @config = config
        end

        def worker
          Worker.new(name, vm, queue, reporter, logger, config)
        end

        def vm
          VirtualMachine::VirtualBox.new(name)
        end

        def queue
          Amqp::Consumer.builds
        end

        def reporter
          Reporter.new(Amqp::Publisher.reporting, logger)
        end

        def logger
          @logger ||= Logger.new("worker:#{name}")
        end

        def config
          @config ||= Travis::Worker.config
        end
      end
    end
  end
end
