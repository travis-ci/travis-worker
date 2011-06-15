require 'resque'
require 'resque/heartbeat'
require 'hashie'
require 'core_ext/ruby/hash/deep_symboliz_keys'

module Travis
  autoload :Job,      'travis/job'
  autoload :Reporter, 'travis/reporter'
  autoload :Shell,    'travis/shell'
  autoload :Worker,   'travis/worker'

  # Main worker dispatcher class that get's instantiated by Resque. Once we get rid of
  # Resque this class can take over the responsibility of popping jobs from the queue.
  #
  # The Worker instantiates jobs (currently based on the payload, should be based on
  # the queue) and runs them.
  class Worker
    autoload :Config, 'travis/worker/config'

    class << self
      attr_reader :vm

      def init
        Resque.redis = ENV['REDIS_URL'] = Travis::Worker.config.redis.url
      end

      def perform(payload)
        @vm = vms.detect { |vm| vm.name == ENV['VM'] }
        new(payload).work!
      end

      def config
        @config ||= Config.new
      end

      def shell
        @shell ||= Travis::Shell::Session.new(vm, vagrant.config.ssh)
      end
      attr_writer :shell

      def available_vms
        @available_vms ||= vms.map { |vm| vm.name }
      end

      def vms
        @vms ||= vagrant.boxes.select { |vm| vm.name =~ /^worker/ }
      end

      def vagrant
        @vagrant ||= begin
          require 'vagrant'
          Vagrant::Environment.new.load!
        end
      end
    end

    attr_reader :payload, :job, :reporter

    def initialize(payload)
      @payload  = payload.deep_symbolize_keys
      @job      = job_type.new(payload)
      @reporter = Reporter::Http.new(job.build)
      job.observers << reporter
    end

    def shell
      self.class.shell
    end

    def work!
      reporter.deliver_messages!
      job.work!
      sleep(0.1) until reporter.finished?
    end

    def job_type
      payload.key?(:build) && payload[:build].key?(:config) ? Job::Build : Job::Config
    end
  end
end
