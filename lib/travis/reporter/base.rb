module Travis
  module Reporter
    class Base
      # Queue is used to synchronize messages
      class Queue < Array
        def shift
          sort! { |lft, rgt| lft[0] <=> rgt[0] }
          yield(first) unless empty?
          super
        end
      end

      attr_reader :messages, :connections

      def initialize
        @messages = Queue.new
        @connections = []
      end

      def register_connection(connection)
        connections << connection
        connection.callback { connections.delete(connection) }
        connection.errback  { connections.delete(connection) }
      end

      def on_start(job)
      end

      def on_data(job, data)
      end

      def on_finish(job)
        sleep(0.1) until worker.messages.empty? && worker.connections.empty?
      end
    end
  end
end
