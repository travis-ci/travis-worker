require 'resque'
require 'resque/plugins/meta'
require 'resque/heartbeat'
require 'eventmachine'
require 'hashie'
require 'core_ext/ruby/hash/deep_symboliz_keys'

module Travis
  # Main worker dispatcher class that get's instantiated by Resque. Once we get rid of
  # Resque this class can take over the responsibility of popping jobs from the queue.
  #
  # The Worker instantiates jobs (currently based on the payload, should be based on
  # the queue) and runs them.
  class Worker
    # TODO can we remove this?
    extend Resque::Plugins::Meta

    class Config < Hashie::Dash
      property :redis,    :default => Hashie::Mash.new(:url => ENV['REDIS_URL'])
      property :reporter, :default => Hashie::Mash.new(:http => Hashie::Mash.new)
    end

    class << self
      def config
        @config ||= Config.new
      end

      def shell
        @shell ||= Travis::Shell::SSH.new(Vagrant::Environment.new.load!)
      end

      def shell=(shell)
        @shell = shell
      end

      def perform(meta_id, payload)
        Resque.redis ||= Travis::Worker.config.redis.url

        EM.run do
          sleep(0.01) until EM.reactor_running?
          EM.defer do
            begin
              new(meta_id, payload).work!
            rescue Exception => e
              $_stdout.puts(e.message)
              e.backtrace.each { |line| $_stdout.puts(line) }
            ensure
              EM.stop
            end
          end
        end
      end
    end

    attr_reader :payload, :job, :reporter

    def initialize(meta_id, payload)
      @meta_id  = meta_id
      @payload  = payload.deep_symbolize_keys
      @job      = job_type.new(payload)

      @reporter = Reporter::Http.new(job.build)
      job.observers << reporter
    end

    def work!
      reporter.deliver_messages!
      job.split_stdout!
      job.work!

      sleep(0.1) until reporter.finished?
    end

    def job_type
      payload.key?(:build) && payload[:build].key?(:config) ? Job::Build : Job::Config
    end
  end
end
