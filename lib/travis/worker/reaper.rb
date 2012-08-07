require 'travis/support'

module Travis
  class Worker
    class Reaper
      include Logging

      def self.live_or_let_die(vm)
        info "monitoring #{vm.name} (pid #{vm.vm_pid}) so that it doesn't exceed 45mins"
        Timeout.timeout(45 * 60) do
          yield
        end
      rescue Timeout::Error => e
        `kill #{vm.vm_pid}`
        info "#{vm.name} (pid #{vm.vm_pid}) forcefully killed"
        sleep 5
        true
      end
    end
  end
end