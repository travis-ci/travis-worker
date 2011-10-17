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

        def reporter
          Reporter.new(reporting)
        end

        def logger
          Util::Logging::Logger.new("worker:#{name}")
        end

        def queue
          Messaging.hub(Travis::Worker.config.queue)
        end

        def reporting
          Messaging.hub('reporting.jobs')
        end

        def config
          @config ||= Travis::Worker.config
        end
      end
    end
  end
end
