module Travis
  module Reporter
    class Base
      def connections
        @connections ||= []
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
      end
    end
  end
end
