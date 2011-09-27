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
    autoload :Reporter,        'travis/worker/reporter'
    autoload :Shell,           'travis/worker/shell'

    class << self


      def config
        @config ||= Config.new
      end


      # @group SSH shell access

      attr_writer :shell

      def discard_shell!
        @shell = nil
      end # discard_shell!

      def shell
        @shell ||= Travis::Worker::Shell::Session.new(vm, vagrant.config.ssh)
      end

      # @endgroup


      # @group AMQP connection

      attr_accessor :amqp_connection

      # @endgroup



      def name
        @name ||= "#{hostname}:#{ENV['VM']}"
      end

      def hostname
        @hostname ||= Socket.gethostname
      end

      def vm
        @vm ||= vagrant.vms[(ENV['VM'] || '').to_sym] || raise(VmNotFound, "could not find vm #{ENV['VM'].inspect}")
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
