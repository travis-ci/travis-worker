require 'travis/worker/version'
require 'socket'

module Travis
  module Worker
    class VmNotFound < RuntimeError; end

    autoload :Application,     'travis/worker/application'
    autoload :BuildDispatcher, 'travis/worker/build_dispatcher'
    autoload :Builder,         'travis/worker/builder'
    autoload :Config,          'travis/worker/config'
    autoload :Job,             'travis/worker/job'
    autoload :JobExecutor,     'travis/worker/job_executor'
    autoload :Reporter,        'travis/worker/reporter'
    autoload :Shell,           'travis/worker/shell'

    class << self

      attr_accessor :messaging_connection

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
  end # Worker
end # Travis
