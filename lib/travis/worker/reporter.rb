module Travis
  module Reporter
    autoload :Base,  'travis/worker/reporter/base'
    autoload :Http,  'travis/worker/reporter/http'
    autoload :Queue, 'travis/worker/reporter/queue'
  end
end
