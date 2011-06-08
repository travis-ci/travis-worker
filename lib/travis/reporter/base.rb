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
        sleep(Job::Stdout::BUFFER_TIME) # ugh ... make sure this is the last message. do we still need this?
        message(:finish, data)
      end

      def deliver_messages!
        # EM.add_periodic_timer(0.1) # why the fuck does this swallow exception output
        EM.defer do
          begin
            messages.shift { |message| deliver_message(message) }
            sleep(0.1)
            deliver_messages!
          rescue
            puts "\n" + $!.inspect + "\n	from  " + $!.backtrace.join("\n	from ")
          end
        end
      end
    end
  end
end
