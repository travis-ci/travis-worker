module Travis
  module Reporter
    class Base
      attr_reader :build, :messages, :connections

      def initialize(build)
        @build = build
        @messages = Queue.new
      end

      def finished?
        messages.empty? && !active? # && connections.empty?
      end

      def active?
      end

      def on_start(data)
        message(:start, data)
      end

      def on_update(data)
        message(:update, data.merge(:incremental => true))
      end

      def on_finish(data)
        message(:finish, data)
      end

      def deliver_messages!
        Thread.abort_on_exception = true

        Thread.new do
          loop do
            messages.shift { |message| deliver_message(message) } unless messages.empty?
            sleep(0.1)
          end
        end
      end
    end
  end
end
