module Travis
  module Worker
    class Worker
      class JobFactory
        attr_reader :vm

        def initialize(vm)
          @vm = vm
        end

        def create(payload)
          Build::Job.runner(vm, vm.shell, http, payload, reporter)
        end

        def reporter
          Reporter.new
        end

        def http
          Build::Connection::Http.new(Travis::Worker.config)
        end
      end
    end
  end
end
