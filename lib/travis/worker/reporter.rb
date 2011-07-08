module Travis
  module Worker
    module Reporter
      autoload :Base,  'travis/worker/reporter/base'
      autoload :Amqp,  'travis/worker/reporter/amqp'
      autoload :Http,  'travis/worker/reporter/http'
      autoload :Queue, 'travis/worker/reporter/queue'
    end # Reporter
  end # Worker
end # Travis
