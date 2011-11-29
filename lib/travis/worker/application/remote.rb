module Travis
  class Worker
    class Application
      class Remote
        include Logging

        def boot(workers = [])
          # TODO use ssh to start the worker app
        end

        def start(workers)
          request(:start, :workers => workers)
        end

        def stop(workers, options)
          request(:stop, options.merge(:workers => workers))
        end

        def reboot(options)
          request(:reboot, options, :listen => false)
        end

        def terminate(options)
          request(:terminate, options, :listen => false)
        end

        def status
          request(:status)
        end

        def config
          request(:config)
        end

        def set(config)
          request(:set, config)
        end

        protected

          def request(command, payload = {}, options = {})
            publish(command, payload)
            listen unless options[:listen] == false
          end
          log :request, :as => :debug

          def publish(command, payload)
            commands.publish(payload.merge(:command => command), :reply_to => 'replies')
          end

          def listen
            set_timeout
            replies.subscribe(:blocking => true) do |message, payload|
              @timeout.kill
              disconnect
              return MultiJson.decode(payload)
            end
          end

          def commands
            Amqp::Publisher.commands
          end

          def replies
            Amqp::Consumer.replies
          end

          def disconnect
            Amqp.disconnect
          end

          def set_timeout
            @timeout = Thread.new do
              sleep(5)
              puts 'Timed out after 5 seconds without any reply'
              java.lang.System.exit(0)
            end
          end
      end
    end
  end
end

# TODO why does this not work? throws https://gist.github.com/f5c2c338cab1eeb6c59b
# Amqp::Consumer.replies.subscribe(:blocking => true, &method(:handle_reply)) if options[:reply]
#
# def handle_reply(message, payload)
#   @timeout.kill
#   Amqp.disconnect
#   MultiJson.decode(payload)
# end

