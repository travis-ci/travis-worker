module Travis
  module Reporter
    class Base
      attr_reader :build, :messages, :connections

      def initialize(build)
        @build = build
        @messages = Queue.new
        @connections = []
      end

      def register_connection(connection)
        connections << connection
        connection.callback { connections.delete(connection) }
        connection.errback  { connections.delete(connection) }
      end

      def finished?
        messages.empty? && connections.empty?
      end

      def on_start(job, data)
        message(:start, data)
      end

      def on_update(job, data)
        message(:update, data.merge(:incremental => true))
      end

      def on_finish(job, data)
        message(:finish, data)
      end

      def deliver_messages!
        Thread.abort_on_exception = true

        Thread.new do
          while true do
            messages.shift { |message| deliver_message(message) } unless messages.empty?
            sleep(0.1)
          end
        end
      end
    end
  end
end
