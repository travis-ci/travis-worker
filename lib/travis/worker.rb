require 'resque'
require 'resque/plugins/meta'
require 'resque/heartbeat'
require 'eventmachine'

module Travis
  # Main worker dispatcher class that get's instantiated by Resque. Once we get rid of
  # Resque this class can take over the responsibility of popping jobs from the queue.
  #
  # The Worker instantiates jobs (currently based on the payload, should be based on
  # the queue) and runs them.
  class Worker
    extend Resque::Plugins::Meta
    include Base

    class << self
      def shell
        @shell ||= Travis::Shell::SSH.new(Vagrant::Environment.new.load!) # allow people to overwrite this with a local shell
      end

      def initialize
        Resque.redis = ENV['REDIS_URL'] || Travis.config['redis']['url']

        @initialized = true
      end

      def initialized?
        !!@initialized
      end

      def perform(meta_id, payload)
        initialize unless initialized?

        EM.run do
          sleep(0.01) until EM.reactor_running?
          EM.defer do
            begin
              worker = new(payload)
              worker.work!
              sleep(0.1) until worker.messages.empty? && worker.connections.empty?
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
