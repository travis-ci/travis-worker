module Travis
  class Worker
    module VirtualMachine
      class VmNotFound   < StandardError; end
      class VmFatalError < StandardError; end

      autoload :VirtualBox, 'travis/worker/virtual_machine/virtual_box'
      autoload :BlueBox,    'travis/worker/virtual_machine/blue_box'
    end
  end
end
