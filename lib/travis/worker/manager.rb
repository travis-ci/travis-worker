module Travis
  module Worker

    # Public: The Worker manager, responsible for starting, monitoring,
    # and stopping Worker instances.
    class Manager

      # Returns an Array of Worker instances.
      attr_reader :workers

      # Returns the MessagingConnection used by the Manager.
      attr_reader :messaging_connection

      # Public: Initialize a Worker Manager.
      #
      # configuration - A Config to use for connection details (default: nil)
      def initialize(configuration = nil)
        config(configuration)
        @workers = []
        @messaging_connection = MessagingConnection.new(config)
      end

      # Public: Connects to the messaging broker and starts the workers.
      #
      # Returns the current instance of the MessagingConnection.
      def start
        messaging_connection.bind
        start_workers
        self
      end

      # Public: Disconnects from the messaging broker and stops all the workers.
      #
      # Returns the current instance of the MessagingConnection.
      def stop
        messaging_connection.unbind
        self
      end


      protected

        # Internal: Starts new workers in new threads.
        #
        # Returns the current instance of the MessagingConnection.
        def start_workers
          jobs_queue = messaging_connection.jobs_queue
          channel    = messaging_connection.channel

          worker_names = Travis::Worker::VirtualMachine::VirtualBox.vm_names

          worker_names.each do |name|
            puts "[boot] Starting #{name}"

            worker = Worker.new(name, jobs_queue, channel)
            workers << worker
            worker.run
          end

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