module Travis
  module Worker
    class Manager
      class Factory
        def manager
          Manager.new(worker_names, messaging, logger, config)
        end

        def messaging
          Messaging
        end

        def logger
          Util::Logging::Logger.new('manager')
        end

        def worker_names
          VirtualMachine::VirtualBox.vm_names
        end

        def config
          Travis::Worker.config
        end
      end
    end
  end
end
