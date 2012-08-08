require 'travis/support'

module Travis
  class Worker
    class Reaper
      include Logging

      log_header { "reaper" }

      def self.live_or_let_die(vm, timeout = 2400)
        reaper = self.new(vm, timeout)
        reaper.work { yield }
      end

      attr_accessor :vm, :timeout, :completed

      def initialize(vm, timeout)
        @vm = vm
        @timeout = timeout
        @completed = false
      end

      def work
        monitor
        result = yield
        @completed = true
        @monitor.kill rescue nil
        result
      end

      private

      def monitor
        info "monitoring #{vm.name} so that it doesn't exceed #{mins}mins"
        @monitor = Thread.new do
          sleep timeout
          unless completed
            pid = vm.vm_pid
            `kill #{pid}`
            info "#{vm.name} (pid #{pid}) forcefully killed"
            sleep 5
          end
        end
      end

      def mins
        timeout / 60
      end
    end
  end
end