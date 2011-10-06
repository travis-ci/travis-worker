require 'travis/worker/version'
require 'socket'

module Travis

  module Worker
    autoload :Application,  'travis/worker/application'
    autoload :Builder,      'travis/worker/builder'
    autoload :Config,       'travis/worker/config'
    autoload :Job,          'travis/worker/job'
    autoload :Manager,      'travis/worker/manager'
    autoload :Messaging,    'travis/worker/messaging'
    autoload :Reporter,     'travis/worker/reporter'
    autoload :Worker,       'travis/worker/worker'

    module Shell
      autoload :Buffer,     'travis/worker/shell/buffer'
      autoload :Helpers,    'travis/worker/shell/helpers'
      autoload :Session,    'travis/worker/shell/session'
    end

    module Util
      autoload :Retryable,  'travis/worker/util/retryable'
    end

    module VirtualMachine
      autoload :VirtualBox, 'travis/worker/virtual_machine/virtual_box'
    end

    class << self
      def config
        @config ||= Config.new
      end

      def hostname
        @hostname ||= Socket.gethostname
      end
    end
  end

end
