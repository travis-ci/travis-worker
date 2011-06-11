require 'resque'
require 'resque/plugins/meta'
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

    # TODO can we remove this?
    extend Resque::Plugins::Meta

    class << self
      attr_reader :vagrant_env

      def config
        @config ||= Config.new
      end

      def shell
        @shell ||= Travis::Shell::Session.new(vagrant_env.primary_vm.vm, vagrant_env.config.ssh)
      end

      def shell=(shell)
        @shell = shell
      end

      def perform(meta_id, payload)
        load_vagrant
        Resque.redis ||= Travis::Worker.config.redis.url
        new(meta_id, payload).work!
      end

      def load_vagrant
        config # TODO triggers loading the config early

        puts 'loading vagrant ...'
        require 'vagrant'

        puts 'loading vagrant env ...'
        @vagrant_env = Vagrant::Environment.new.load!
      end
    end

    attr_reader :payload, :job, :reporter

    def initialize(meta_id, payload)
      @meta_id  = meta_id
      @payload  = payload.deep_symbolize_keys
      @job      = job_type.new(payload)
      @reporter = Reporter::Http.new(job.build)

      job.observers << reporter
      shell.on_output do |process, data|
        print data
        job.update(:log => data)
      end
    end

    def shell
      self.class.shell
    end

    def work!
      reporter.deliver_messages!
      job.work!
      sleep(0.1) until reporter.finished?
      shell.close
    end

    def job_type
      payload.key?(:build) && payload[:build].key?(:config) ? Job::Build : Job::Config
    end
  end
end
