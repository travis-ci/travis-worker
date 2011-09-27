module Travis
  module Worker
    module Job
      autoload :Base,   'travis/worker/job/base'
      autoload :Build,  'travis/worker/job/build'
      autoload :Config, 'travis/worker/job/config'

      class << self
        def create(payload)
          clazz = payload.key?(:build) && payload[:build].key?(:config) ? Job::Build : Job::Config
          clazz.new(payload)
        end
      end
    end # Job
  end # Worker
end # Travis
