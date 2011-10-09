module Travis
  module Worker
    class Worker
      class JobFactory
        attr_reader :vm

        def initialize(vm)
          @vm = vm
        end

        def create(payload)
          Build::Job.runner(vm, vm.shell, http, payload, Reporter.new)
        end

        def http
          Build::Connection::Http.new(Travis::Worker.config) # TODO can we reuse this? is faraday thread-safe?
        end
      end
    end
  end
end
