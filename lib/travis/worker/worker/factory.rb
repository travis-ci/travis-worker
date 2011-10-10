module Travis
  module Worker
    class Worker
      class Factory
        attr_reader :name

        def intialize(name)
          @name = name
        end

        def worker
          Worker.new(queue, vm, reporter, logger, config)
        end

        def vm
          VirtualMachine::VirtualBox.new(name)
        end

        def reporter
          Reporter.new(reporting)
        end

        def logger
          Util::Logging::Logger.new(vm.name)
        end

        def reporting
          Messaging.hub('reporting.jobs')
        end

        def queue
          Messaging.hub('builds')
        end

        def config
          Travis::Worker.config
        end
      end
    end
  end
end
