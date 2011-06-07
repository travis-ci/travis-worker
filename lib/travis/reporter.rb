module Travis
  module Reporter
    autoload :Base,  'travis/reporter/base'
    autoload :Http,  'travis/reporter/http'
    autoload :Queue, 'travis/reporter/queue'
  end
end
