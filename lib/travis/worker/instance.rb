require 'simple_states'
require 'multi_json'
require 'thread'
require 'celluloid'
require 'core_ext/hash/compact'
require 'travis/build'
require 'travis/support'
require 'travis/worker/factory'
require 'travis/worker/virtual_machine'
require 'travis/worker/reporters'
require 'travis/worker/utils/hard_timeout'
require 'travis/worker/utils/serialization'

module Travis
  module Worker
    class Instance
      class BuildStallTimeoutError < StandardError; end

      include Celluloid
      include SimpleStates, Logging

      log_header { "#{name}:worker:instance" }

      def self.create(name, config, broker_connection)
        Factory.new(name, config, broker_connection).worker
      end

      states :created, :starting, :ready, :working, :stopping, :stopped, :errored

      attr_accessor :state
      attr_reader   :name, :vm, :broker_connection, :queue, :queue_name,
                    :subscription, :config, :payload, :last_error, :observers

      def initialize(name, vm, broker_connection, queue_name, config, observers = [])
        raise ArgumentError, "worker name cannot be nil!" if name.nil?
        raise ArgumentError, "VM cannot be nil!" if vm.nil?
        raise ArgumentError, "broker connection cannot be nil!" if broker_connection.nil?
        raise ArgumentError, "config cannot be nil!" if config.nil?

        @name              = name
        @vm                = vm
        @queue_name        = queue_name
        @broker_connection = broker_connection
        @config            = config
        @observers         = Array(observers)
      end

      def start
        set :starting
        vm.prepare
        open_channels
        declare_queues
        subscribe
        set :ready
      end
      log :start

      # need to relook at this method as it feels wrong to
      # report a worker at stopping while it is also working
      def stop(options = {})
        set :stopping
        unsubscribe
        kill if options[:force]
        set :stopped unless working?
      end
      log :stop

      def kill
        vm.shell.terminate("Worker #{name} was stopped forcefully.")
      end

      def process(message, payload)
        work(message, payload)
      rescue Errno::ECONNREFUSED, Exception => error
        # puts error.message, error.backtrace
        error_build(error, message)
      end

      def work(message, payload)
        prepare(payload)

        info "starting job slug:#{self.payload['repository']['slug']} id:#{self.payload['job']['id']}"
        info "this is a requeued message" if message.redelivered?

        build_log_streamer = log_streamer(message, payload)

        build = Build.create(vm, vm.shell, build_log_streamer, self.payload, config)
        hard_timeout(build)

        finish(message)
      rescue BuildStallTimeoutError => e
        error "the job (slug:#{self.payload['repository']['slug']} id:#{self.payload['job']['id']}) stalled and was requeued"
        finish(message, :requeue => true)
      rescue VirtualMachine::VmFatalError => e
        error "the job (slug:#{self.payload['repository']['slug']} id:#{self.payload['job']['id']}) was requeued as the vm had a fatal error"
        finish(message, :requeue => true)
      ensure
        build_log_streamer.close if build_log_streamer
      end
      log :work, :as => :debug

      def report
        { :name => name, :host => host, :state => state, :last_error => last_error, :payload => payload }
      end

      def shutdown
        unsubscribe
      end

      protected

      def open_channels
        # error handling happens on the per-channel basis, so using
        # one channel for one type of operation is a highly recommended practice. MK.
        build_channel
        reporting_channel
      end

      def close_channels
        # channels may be nil in some tests that mock out #start and #stop. MK.
        build_channel.close if build_channel.open?
        reporting_channel.close if reporting_channel && reporting_channel.open?
      end

      def build_channel
        # technically there is no need to use one channel per consumer but with RabbitMQ version on
        # Heroku (2.5) this is the only way to go :/ 2.6 and 2.7 on my local network work just fine.
        # But hey, Heroku gods, we must obey to. For now. MK.
        @build_channel ||= begin
          channel = broker_connection.create_channel
          channel.prefetch = 1
          channel
        end
      end

      def reporting_channel
        @reporting_channel ||= broker_connection.create_channel
      end

      def declare_queues
        @queue = build_channel.queue(queue_name, :durable => true)

        # these are declared here mostly to aid development purposes. MK
        reporting_channel = broker_connection.create_channel
        reporting_channel.queue("reporting.jobs.builds", :durable => true)
        reporting_channel.queue("reporting.jobs.logs",   :durable => true)
      end

      def subscribe
        @subscription = queue.subscribe(:ack => true, :blocking => false, &method(:process))
      end

      def unsubscribe
        # due to some aspects of how RabbitMQ Java client works and HotBunnies consumer
        # implementation that uses thread pools (JDK executor services), we need to shut down
        # consumers manually to guarantee that after disconnect we leave no active non-daemon
        # threads (that are pretty much harmless but JVM won't exit as long as they are running). MK.
        return unless subscription
        unless working?
          info "Unsubscribing from #{queue_name} right now"
          subscription.cancel
          set :stopped
        else
          graceful_shutdown
        end
      rescue StandardError => e
        info "Subscription is still active"
        graceful_shutdown
      end

      def graceful_shutdown
        info "Unsubscribing from #{queue_name} once the current job has finished"
        @shutdown = true
      end

      def set(state)
        self.state = state
        observers.each { |observer| observer.notify(report) }
        state
      end

      def prepare(payload)
        @last_error = nil
        @payload = decode(payload)
        Travis.uuid = @payload.delete(:uuid)
        set :working
      end
      log :prepare, :as => :debug

      def finish(message, opts = {})
        if @shutdown
          set :stopping
          unsubscribe
        end

        unless opts[:requeue]
          message.ack
        else
          message.reject(:requeue => true)
        end

        @payload = nil

        if working?
          set :ready
        elsif stopping?
          set :stopped
        end
      end
      log :finish, :params => false

      def error_build(error, message)
        @last_error = [error.message, error.backtrace].flatten.join("\n")
        log_exception(error)
        message.reject(:requeue => true)
        stop
        set :errored
      end
      log :error, :as => :debug

      def log_streamer(message, payload)
        Reporters::LogStreamer.new(name, broker_connection.create_channel, broker_connection.create_channel)
      end

      def host
        Travis::Worker.config.host
      end

      def decode(payload)
        Hashr.new(MultiJson.decode(payload))
      end

      def hard_timeout(build)
        Utils::HardTimeout.timeout(config.timeouts.hard_limit) do
          Thread.current[:log_header] = name
          build.run
        end
      rescue Timeout::Error => e
        build.vm_stall
        raise BuildStallTimeoutError, 'The VM stalled and the hardtimeout fired'
      end
    end
  end
end
