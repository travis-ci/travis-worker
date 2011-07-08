module Travis
  module Worker
    module Reporter
      class Amqp < Base

        def initialize(build)
          @build    = build
          @messages = Queue.new
        end


        #
        # Implementation
        #

        protected

        def active?
          !!@active
        end

        def message(type, data)
        end

        def deliver_message(message)
          @active = true

          puts(message)

          # TODO
        rescue
          puts "---> exception sending message #{message.inspect}.\n  #{$!.inspect}\n#{$@}"
        ensure
          @active = false
        end

        def config
          @config ||= Hash.new
        end
      end # Http
    end # Reporter
  end # Worker
end # Travis
