module Travis
  module Worker

    # The Worker manager, responsible for starting, monitoring,
    # and stopping Worker instances.
    class Manager

      # Returns an Array of Worker instances.
      attr_reader :workers

      # Returns the MessagingConnection used by the Manager.
      attr_reader :messaging_hub

      # Initialize a Worker Manager.
      #
      # configuration - A Config to use for connection details (default: nil)
      def initialize(configuration = nil)
        config(configuration)
        @workers = []
        @messaging_hub = MessagingHub.new(config)
      end

      # Connects to the messaging broker and starts the workers.
      #
      # Returns the current instance of the MessagingConnection.
      def start
        messaging_hub.bind
        start_workers
        self
      end

      # Disconnects from the messaging broker and stops all the workers.
      #
      # Returns the current instance of the MessagingConnection.
      def stop
        messaging_hub.unbind
        self
      end


      protected

        # Internal: Starts new workers in new threads.
        #
        # Returns the current instance of the MessagingConnection.
        def start_workers
          jobs_queue = messaging_hub.jobs_queue
          channel    = messaging_hub.channel

          worker_names = Travis::Worker::VirtualMachine::VirtualBox.vm_names

          worker_names.each do |name|
            puts "[boot] Starting #{name}"

            worker = Worker.new(name, jobs_queue, channel)
            workers << worker
            worker.run
          end

          messaging_hub.prefetch_messages = workers.count

          self
        end


      private

        def config(configuration = nil)
          @config ||= configuration || Travis::Worker.config
          @config
        end
    end

  end
end