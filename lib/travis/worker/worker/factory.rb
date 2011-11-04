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
          Reporter.new(reporting, logger)
        end

        def queue
          queue ||= Messaging.hub(Travis::Worker.config.queue)
        end

        def logger
          @logger ||= Util::Logging::Logger.new("worker:#{name}")
        end

        def reporting
          @reporting ||= Messaging.hub('reporting.jobs')
        end

        def config
          @config ||= Travis::Worker.config
        end
      end
    end
  end
end
