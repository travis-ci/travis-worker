require 'java'
require 'march_hare'
require 'metriks'
require 'metriks/reporter/librato_metrics'
require 'raven'
require 'travis/support/amqp'
require 'travis/support/logger'
require 'travis/worker/pool'
require 'travis/worker/application/commands/dispatcher'
require 'travis/worker/application/heart'
require 'travis/worker/application/http_heart'
require 'travis/worker/application/remote'

module Travis
  module Worker
    class Application
      include Logging

      def initialize
        Travis::Logger.configure(Travis.logger)
        Travis::Amqp.config = config.amqp

        if config.sentry.dsn
          Raven.configure do |raven_config|
            raven_config.dsn = config.sentry.dsn
          end
        end

        # due to https://rails.lighthouseapp.com/projects/8994/tickets/1112-redundant-utf-8-sequence-in-stringto_json
        # we should use ok_json
        # bad (AS::JSON) : http://staging.travis-ci.org/#!/travis-repos/rake-pipeline/builds/367776
        # good (ok_json) : http://staging.travis-ci.org/#!/travis-repos/rake-pipeline/builds/367791
        MultiJson.engine = :ok_json
      end

      def boot(options = {})
        @start_hook = options[:start_hook]
        @stop_hook = options[:stop_hook]
        http_heart(options[:heartbeat_url]).start if options[:heartbeat_url]
        install_signal_traps
        start_metriks
        start_commands_dispatcher
        start(options)
        heart.start
        sleep
        # remove this for now, there seem to be bugs with this and it can leave vms in an unusable state
        # Command.subscribe(self, config, broker_connection.create_channel)
      end
      log :boot

      def start(options = {})
        system "#{@start_hook}" if @start_hook
        workers.start(options[:workers] || [])
      end
      log :start

      def stop(options = {})
        workers.stop(options.delete(:workers) || [], options)
      end
      log :stop

      def status(*)
        workers.status
      end

      def set(config)
        config.each { |path, value| self.config.set(path, value) }
      end

      def terminate(options = {})
        stop(options)
        @http_heart.stop if @http_heart
        stop_commands_dispatcher
        disconnect
        update if options[:update]
        reboot if options[:reboot]
        quit
      end
      log :terminate

      def broker_connection
        @broker_connection ||= MarchHare.connect(amqp_config)
      end

      protected

      def amqp_config
        amqp_config = config.fetch(:amqp, Hashr.new)
        amqp_config.merge!(:thread_pool_size => (vm_count * 3 + 3))
      end

      def vm_count
        config.fetch(:vms, {}).fetch(:count, 0)
      end

      def config
        Travis::Worker.config
      end

      def start_commands_dispatcher
        @commands ||= Commands::Dispatcher.new(workers)
        @commands.start
      end

      def http_heart(heartbeat_url)
        @http_heart ||= HTTPHeart.new(heartbeat_url, -> { graceful_shutdown })
      end

      def stop_commands_dispatcher
        @commands.shutdown
      end

      def workers
        @workers ||= Pool.create(broker_connection)
      end

      def heartbeat_channel
        @heartbeat_channel ||= broker_connection.create_channel
      end

      def heart
        @heart ||= Heart.new(heartbeat_channel) { { :workers => workers.status } }
      end

      def update
        execute <<-sh
            git reset --hard
            git pull
            bundle install
          sh
      end
      log :update

      def reboot
        # unfortunately fork is not available on jruby
        # system('nohup thor travis:worker:boot > log/worker.log &') if fork.nil?
        system('echo "thor travis:worker:boot >> log/worker.log 2>&1" | at now')
        info "reboot scheduled"
      end

      def execute(commands)
        commands.split("\n").each do |command|
          info(command.strip)
          system("#{command.strip} >> log/worker.log 2>&1")
        end
      end

      def disconnect
        heart.stop
        broker_connection.close if broker_connection.open?
        sleep(0.5)
      end
      log :disconnect

      def quit
        system "#{@stop_hook}" if @stop_hook
        java.lang.System.exit(0)
      end

      def install_signal_traps
        Signal.trap('INT')  { graceful_shutdown }
        Signal.trap('TERM') { graceful_shutdown }
      end

      def graceful_shutdown
        return if @graceful_shutdown
        @graceful_shutdown = true
        shutdown_at = Time.now + Travis::Worker.config.shutdown_timeout

        info "Gracefully shutting down all workers"

        workers.each_worker { |worker| worker.shutdown }

        loop do
          sleep 10

          if Time.now > shutdown_at
            info "Graceful timeout expired, shutting down"
            quit
          end

          if workers_stopped?
            info "All workers stopped, shutting down"
            quit
          end

          info "Waiting for #{active_workers} workers to finish their current jobs"
        end
      end

      def start_metriks
        librato = Travis::Worker.config.librato
        if librato
          @reporter = Metriks::Reporter::LibratoMetrics.new(librato['email'], librato['token'], :source => Travis::Worker.config.host)
          @reporter.start
        end
      end

      def workers_stopped?
        active_workers == 0
      end

      def active_workers
        workers.status.map { |status| status[:state] }.reject {|state| [:stopped, :errored].include?(state)}.count
      end
    end
  end
end
