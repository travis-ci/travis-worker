module Travis
  module Shell

    #
    # Behaviors
    #

    autoload :Session, 'travis/shell/session'


    #
    # API
    #

    NEWLINE = "\n"

    # @see Travis::Shell::Session#execute
    def exec(*args)
      Travis::Worker.shell.execute(*args)
    end

    def echoize(cmd)
      [cmd].flatten.
        join(NEWLINE).
        split(NEWLINE).
        map { |cmd| "echo #{Shellwords.escape("$ #{cmd}")}#{NEWLINE}#{cmd}" }.
        join(NEWLINE)
    end # echoize
  end # Shell
end # Travis
