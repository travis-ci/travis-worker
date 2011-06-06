module Travis
  module Jobs
    # Job base class. Implements an observer pattern so Reporters can hook in
    # unobstrusively, holds the payload data and provides the main public `work!`
    # method.
    class Base
      include Travis::Shell

      attr_reader :repository, :payload, :started_at, :finished_at, :log, :result

      def initialize(payload)
        @payload   = payload
        @observers = []
      end

      def work!
        start
        result = perform
        finish(result)
      end

      protected

        def repository
          @repository ||= Repository.new(shell, payload['repository'], payload['build']['config'])
        end

        def start(data = {})
          notify(:start, data)
        end

        def finish(data = {})
          notify(:finish, data)
        end

        def notify(event, *args)
          observers.each do |observer|
            observer.send(:"on_#{event}", self, *args) if observer.respond_to?(:"on_#{event}")
          end
        end
    end
  end
end
