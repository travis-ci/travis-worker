require "multi_json"

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
        @queue.subscribe(:ack => true, &method(:handle_message))
        announce "[builds.dispatcher] Add consumer for the '#{@queue.name}' queue."

        self
      end # run


      def handle_message(metadata, payload)
        deserialized = MultiJson.decode(payload)
        announce "[builds.dispatcher] Handling #{deserialized.inspect}"

        # TODO: defer it
        Workers::Amqp.new(metadata, deserialized).work!
        metadata.ack
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
