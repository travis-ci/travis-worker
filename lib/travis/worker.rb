require 'resque'
require 'resque/plugins/meta'
require 'resque/heartbeat'
require 'eventmachine'
require 'hashie'

module Travis
  # Main worker dispatcher class that get's instantiated by Resque. Once we get rid of
  # Resque this class can take over the responsibility of popping jobs from the queue.
  #
  # The Worker instantiates jobs (currently based on the payload, should be based on
  # the queue) and runs them.
  class Worker
    extend Resque::Plugins::Meta

    class Config < Hashie::Dash
      property :redis,    :default => Hashie::Mash.new(:url => ENV['REDIS_URL'])
      property :reporter, :default => Hashie::Mash.new
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
              # TODO this should be based on the queue, not some arbitrary payload data being present
              type = !payload.key?('config') ? Config : Build
              job = type.new(Hashie::Mash.new(payload))

              reporter = Reporter::Http.new(job.build)
              job.observers << reporter

              reporter.deliver_messages!
              job.split_stdout!
              job.perform!

              sleep(0.1) until reporter.finished?
              EM.stop
            rescue Exception => e
              $_stdout.puts(e.message)
              e.backgtrace.each { |line| $_stdout.puts(line) }
            end
          end
        end
      end
    end
  end
end
