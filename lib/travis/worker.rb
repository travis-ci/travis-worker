require "travis/worker/version"

require 'resque'
require 'resque/heartbeat'
require 'hashie'
require 'travis/worker/core_ext/ruby/hash/deep_symboliz_keys'

module Travis
  module Worker
    class VmNotFound < RuntimeError; end

    autoload :Config,   'travis/worker/config'
    autoload :Job,      'travis/worker/job'
    autoload :Reporter, 'travis/worker/reporter'
    autoload :Shell,    'travis/worker/shell'
    autoload :Worker,   'travis/worker/worker'

    class << self
      attr_writer :shell

      def init
        Resque.redis = ENV['REDIS_URL'] = Travis::Worker.config.redis.url
      end

      def perform(payload)
        Worker.new(payload).work!
      end

      def config
        @config ||= Config.new
      end

      def shell
        instance_variable_defined?(:@shell) ? @shell : @shell = Travis::Worker::Shell::Session.new(vm, vagrant.config.ssh)
      end

      def name
        @name ||= "#{hostname}:#{ENV['VM']}"
      end

      def hostname
        @hostname ||= `hostname`.chomp
      end

      def vm
        @vm ||= vagrant.vms[(ENV['VM'] || '').to_sym] || raise(VmNotFound, "could not find vm #{ENV['VM'].inspect}")
      end

      def vagrant
        @vagrant ||= begin
          require 'vagrant'
          Vagrant::Environment.new.load!
        end
      end
    end
  end # Worker
end # Travis
