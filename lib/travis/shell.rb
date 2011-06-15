module Travis
  module Shell

    #
    # Behaviors
    #

    autoload :Buffer,  'travis/shell/buffer'
    autoload :Helpers, 'travis/shell/helpers'
    autoload :Session, 'travis/shell/session'

    #
    # API
    #

    # @see Travis::Shell::Session#execute
    def exec(*args)
      Travis::Worker.shell.execute(*args)
    end

    def sandboxed(&block)
      Travis::Worker.shell.sandboxed(&block)
    end
  end # Shell
end # Travis
