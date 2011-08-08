module Travis
  module Worker
    module Job
      autoload :Base,       'travis/worker/job/base'
      autoload :Build,      'travis/worker/job/build'
      autoload :Config,     'travis/worker/job/config'
    end # Job
  end # Worker
end # Travis
