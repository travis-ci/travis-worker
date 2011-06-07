module Travis
  module Job
    autoload :Base,       'travis/job/base'
    autoload :Build,      'travis/job/build'
    autoload :Config,     'travis/job/config'
    autoload :Repository, 'travis/job/repository'
    autoload :Stdout,     'travis/job/stdout'
  end
end
