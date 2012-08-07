module Travis
  class Worker
    class Reaper
      def self.live_or_let_die(vm)
        Timeout.timeout(45 * 60) do
          yield
        end
      rescue Timeout::Error => e
        `kill #{vm.vm_pid}`
        sleep 5
        true
      end
    end
  end
end