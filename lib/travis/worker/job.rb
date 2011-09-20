module Travis
  module Worker
    module Job
      autoload :Base,       'travis/worker/job/base'
      autoload :Build,      'travis/worker/job/build'
      autoload :Config,     'travis/worker/job/config'

      module Helpers
        autoload :Repository, 'travis/worker/job/helpers/repository'
      end
    end # Job
  end # Worker
end # Travis
