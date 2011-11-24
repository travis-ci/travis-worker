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
          Worker.new(name, vm, queue, reporter, config)
        end

        def vm
          VirtualMachine::VirtualBox.new(name)
        end

        def queue
          Amqp::Consumer.builds
        end

        def reporter
          Reporter.new(name, Amqp::Publisher.reporting)
        end

        def config
          @config ||= Travis::Worker.config
        end
      end
    end
  end
end
