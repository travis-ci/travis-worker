require 'travis/worker/utils/serialization'

module Travis
  module Worker
    class Application
      class Remote
        include Logging, Utils::Serialization

        def initialize
          Travis.logger.level = Logger.const_get(Travis::Worker.config.log_level.to_s.upcase) # TODO hrmm ...
          Travis::Amqp.config = Travis::Worker.config.amqp
        end

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
            options[:listen] == false ? disconnect : listen
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

              decode(payload)
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
