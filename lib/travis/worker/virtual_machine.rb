require 'active_support/inflector'

module Travis
  class Worker
    module VirtualMachine
      class VmNotFound < StandardError; end

      autoload :VirtualBox, 'travis/worker/virtual_machine/virtual_box'
      autoload :BlueBox,    'travis/worker/virtual_machine/blue_box'

      def self.provider
        provider_name = Travis::Worker.config.vms.provider.camelize

        self.const_get(provider_name)
      end
    end
  end
end
