require 'socket'
require 'travis/support'

module Travis
  module Worker
    autoload :Amqp,         'travis/worker/amqp'
    autoload :Application,  'travis/worker/application'
    autoload :Config,       'travis/worker/config'
    autoload :Manager,      'travis/worker/manager'
    autoload :Reporter,     'travis/worker/reporter'
    autoload :Worker,       'travis/worker/worker'

    module Shell
      autoload :Buffer,     'travis/worker/shell/buffer'
      autoload :Helpers,    'travis/worker/shell/helpers'
      autoload :Session,    'travis/worker/shell/session'
    end

    module VirtualMachine
      autoload :VirtualBox, 'travis/worker/virtual_machine/virtual_box'
    end

    class << self
      def config
        @config ||= Config.new
      end

      def name
        @name ||= hostname.split('.').first
      end

      def hostname
        @hostname ||= Socket.gethostname
      end

      def names
        VirtualMachine::VirtualBox.vm_names
      end
    end
  end
end
