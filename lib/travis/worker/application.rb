require "amqp"
require "travis/worker/core_ext/ruby/hash/deep_symbolize_keys"

module Travis
  module Worker
    class Application

      #
      # API
      #

      def initialize(configuration)
        @configuration = configuration
      end # initialize

      def bind(connection_options)
        self.install_signal_traps

        announce "[boot] About to connect..."

        handlers = {
          :on_tcp_connection_failure          => self.method(:on_tcp_connection_failure).to_proc,
          :on_possible_authentication_failure => self.method(:on_possible_authentication_failure).to_proc
        }
        AMQP.start(connection_options.merge(handlers), &method(:on_connection))
      end # bind


      def unbind
        @connection.disconnect { self.announce("[shutdown] Unbinding..."); EventMachine.stop }
      end # unbind



      #
      # Implementation
      #


      # @group Connection Lifecycle

      def on_connection(connection)
        announce "[boot] Connected to an AMQP broker at #{connection.broker_endpoint} using username #{connection.username}"
        @connection = connection

        self.open_channels
        self.initialize_dispatcher
      end # on_connection(connection)

      def on_tcp_connection_failure(settings)
        announce "[boot] Failued to connect to #{settings[:host]}:#{settings[:port]}"
        EventMachine.stop { exit }
      end # on_tcp_connection_failure(settings)

      def on_possible_authentication_failure(settings)
        announce "[boot] Failued to authenticate at #{settings[:host]}:#{settings[:port]}/#{settings[:vhost]}, username used: #{settings[:user]}"
        EventMachine.stop { exit }
      end # on_possible_authentication_failure(settings)

      protected

      def open_channels
        @heartbeat_channel    = AMQP::Channel.new(@connection, :auto_recovery => true).prefetch(1)
        @commands_channel     = AMQP::Channel.new(@connection, :auto_recovery => true).prefetch(1)
        @reporting_channel    = AMQP::Channel.new(@connection, :auto_recovery => true).prefetch(1)
      end # open_channels

      def initialize_dispatcher
        self.declare_queues

        @dispatcher           = BuildDispatcher.new(@build_requests_queue, @reporting_channel)
        @dispatcher.run
      end # initialize_dispatcher

      def declare_queues
        raise "Commands channel is not initialized" unless @commands_channel

        @build_requests_queue = @commands_channel.queue("builds", :durable => true, :auto_delete => false)
      end # declare_queues

      # @endgroup




      # @group Signal Traps

      public

      def handle_sigint(_)
        self.unbind
      end # handle_sigint(_)

      def handle_sigterm(_)
        self.unbind
      end # handle_sigterm(_)

      def handle_sigusr2(_)
      end # handle_sigusr2(_)

      # @endgroup




      protected

      def install_signal_traps
        Signal.trap("INT",  &method(:handle_sigint))
        Signal.trap("TERM", &method(:handle_sigterm))
        Signal.trap("USR2", &method(:handle_sigusr2))
      end # install_signal_traps

      def announce(what)
        puts what
      end # announce(what)

    end # Application
  end # Worker
end # Travis
