require 'eventmachine'
require 'resque/plugins/meta'

module Travis
  class Worker
    # autoload :Base,   'travis/worker/base'
    # autoload :Pusher, 'travis/worker/pusher'
    # autoload :Rails,  'travis/worker/rails'
    # autoload :Stdout, 'travis/worker/stdout'
    autoload :SSH,    'travis/worker/ssh'

    extend Resque::Plugins::Meta
    include Base

    class << self
      def initialize
        require 'resque/heartbeat'

        include Travis::Builder::Stdout
        include Travis::Builder::Rails

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
              runner = Travis::Shell::SSH.new(Vagrant::Environment.new.load!)
              worker = new(runner, meta_id, payload)
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
