module Travis
  class Worker
    module Shell
      autoload :Buffer,     'travis/worker/shell/buffer'
      autoload :Helpers,    'travis/worker/shell/helpers'
      autoload :Session,    'travis/worker/shell/session'
    end
  end
end
