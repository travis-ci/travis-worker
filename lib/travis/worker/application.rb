require 'java'
require 'hot_bunnies'
require 'metriks'
require 'metriks/reporter/librato_metrics'
require 'travis/worker/pool'
require 'travis/worker/application/command'
require 'travis/worker/application/heart'
require 'travis/worker/application/remote'

module Travis
  module Worker
    class Application
      include Logging

      def initialize
        Travis.logger.level = Logger.const_get(config.log_level.to_s.upcase)
        Travis.logger.formatter = proc { |*args| Travis::Logging::Format.format(*args) }

        Travis::Amqp.config = config.amqp

        # due to https://rails.lighthouseapp.com/projects/8994/tickets/1112-redundant-utf-8-sequence-in-stringto_json
        # we should use ok_json
        # bad (AS::JSON) : http://staging.travis-ci.org/#!/travis-repos/rake-pipeline/builds/367776
        # good (ok_json) : http://staging.travis-ci.org/#!/travis-repos/rake-pipeline/builds/367791
        MultiJson.engine = :ok_json
      end

      def boot(options = {})
        install_signal_traps
        start_metriks
        start(options)
        heart.start
        sleep
        # remove this for now, there seem to be bugs with this and it can leave vms in an unusable state
        # Command.subscribe(self, config, broker_connection.create_channel)
      end
      log :boot

      def start(options = {})
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
        Command.shutdown
        disconnect
        update if options[:update]
        reboot if options[:reboot]
        quit
      end
      log :terminate

      def broker_connection
        @broker_connection ||= HotBunnies.connect(config.fetch(:amqp, Hashr.new))
      end

      protected

      def config
        Travis::Worker.config
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
        java.lang.System.exit(0)
      end

      def install_signal_traps
        Signal.trap('INT')  { graceful_shutdown }
        Signal.trap('TERM') { graceful_shutdown }
      end

      def graceful_shutdown
        return if @graceful_shutdown
        @graceful_shutdown = true

        info "Gracefully shutting down all workers"

        workers.each_worker { |worker| worker.shutdown }

        loop do
          sleep 3
          quit if workers_stopped?
          info "Waiting for all workers to finish their current jobs"
        end
      end

      def start_metriks
        librato = Travis::Worker.config.librato
        if librato
          @reporter = Metriks::Reporter::LibratoMetrics.new(librato['email'], librato['token'])
          @reporter.start
        end
      end

      def workers_stopped?
        workers.status.map { |status| status[:state] }.all? { |state| state == :stopped || state == :errored }
      end
    end
  end
end
