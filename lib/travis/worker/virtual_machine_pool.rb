require 'celluloid'

require 'travis/worker/virtual_machine'

module Travis
  module Worker
    class VirtualMachinePool
      include Celluloid
      include Logging

      def initialize
        @pool = []

        start_pool
        preboot_vms
      end

      def get_session(opts={})
        vm = find_vm
        return nil unless vm
        vm.sandboxed(opts) do
          yield vm.session, vm.full_name
        end
        @pool << vm
        preboot_vms
      end

      private

      def pool_size
        VirtualMachine.provider.vm_count
      end

      def start_pool
        info "Preparing VM pool"
        VirtualMachine.provider.vm_names.each do |name|
          vm = VirtualMachine.provider.new(name)
          vm.prepare
          @pool << vm
        end
        info "Prepared VM pool"
      end

      def preboot_vms
        info "Pre-booting VMs"
        while running_vm_count < pool_size / 2
          vm = @pool.find { |vm| !vm.running }
          break unless vm
          info "Pre-booting vm #{vm.full_name}"
          vm.create_server
        end
        info "Done pre-booted VMs, #{running_vm_count} VMs are running"
      end

      def running_vm_count
        @pool.count(&:running)
      end

      def find_vm
        index = @pool.index(&:running)
        if index
          @pool.delete_at(index)
        else
          @pool.pop
        end
      end
    end
  end
end
