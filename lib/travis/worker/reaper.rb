require 'travis/support'

module Travis
  class Worker
    class Reaper
      extend Logging

      def self.log_header
        "reaper"
      end

      def self.live_or_let_die(vm)
        info "monitoring #{vm.name} so that it doesn't exceed 45mins"
        done = false
        stupid_timeout = Thread.new do
          sleep 45 * 60
          unless done
            `kill #{vm.vm_pid}`
            info "#{vm.name} (pid #{vm.vm_pid}) forcefully killed"
            sleep 5
          end
        end
        result = yield
        done = true
        stupid_timeout.kill rescue nil
        result
      end
    end
  end
end