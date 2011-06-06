module Travis
  module Reporter
    autoload :Base,   'travis/reporter/base'
    autoload :Http,   'travis/reporter/http'
    autoload :Stdout, 'travis/reporter/stdout'
  end
end
