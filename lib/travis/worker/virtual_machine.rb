module Travis
  class Worker
    module VirtualMachine
      class VmNotFound   < StandardError; end
      class VmFatalError < StandardError; end

      autoload :VirtualBox, 'travis/worker/virtual_machine/virtual_box'
    end
  end
end
