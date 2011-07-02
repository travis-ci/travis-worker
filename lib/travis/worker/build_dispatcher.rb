module Travis
  module Worker
    class BuildDispatcher

      #
      # API
      #

      def initialize(queue, reporting_channel)
        @queue             = queue
        @reporting_channel = reporting_channel
      end # initialize(queue, reporting_channel)


      def run
        announce "[builds.dispatcher] Using '#{@queue.name}' queue."
        @queue.subscribe(:ack => true, &method(:handle_message))
      end # run


      def handle_message(metadata, payload)
        # TBD
      end # handle_message(metadata, payload)



      #
      # Implementation
      #

      protected

      def announce(what)
        puts what
      end # announce(what)

    end # BuildDispatcher
  end # Worker
end # Travis
