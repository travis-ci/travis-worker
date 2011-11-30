module Travis
  class Worker
    class Reporter
      include Logging

      log_header { "reporter:#{name}" }

      attr_reader :name, :jobs, :workers

      def initialize(name, jobs, workers)
        @name = name
        @jobs = jobs
        @workers = workers
      end

      def notify(event, data)
        message(event, data)
      end

      def message(event, data)
        target = event =~ /worker:*/ ? workers : jobs
        target.publish(data, :properties => { :type => event.to_s })
      end
      log :message, :as => :debug
    end
  end
end
