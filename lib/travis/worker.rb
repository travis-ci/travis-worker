require 'travis/worker/version'
require 'socket'

module Travis
  module Worker
    class VmNotFound < RuntimeError; end

    autoload :Application,          'travis/worker/application'
    autoload :Builder,              'travis/worker/builder'
    autoload :Config,               'travis/worker/config'
    autoload :Job,                  'travis/worker/job'
    autoload :Manager,              'travis/worker/manager'
    autoload :MessagingConnection,  'travis/worker/messaging_connection'
    autoload :Reporter,             'travis/worker/reporter'
    autoload :Shell,                'travis/worker/shell'
    autoload :Worker,               'travis/worker/worker'

    class << self
      def config
        @config ||= Config.new
      end

      attr_writer :shell

      def discard_shell!
        @shell = nil
      end

      def shell
        @shell ||= Travis::Worker::Shell::Session.new(vm, vagrant.config.ssh)
      end

      def hostname
        @hostname ||= Socket.gethostname
      end

      def vagrant
        @vagrant ||= begin
          require 'vagrant'
          ::Vagrant::Environment.new.load!
        end
      end
    end

  end
end
