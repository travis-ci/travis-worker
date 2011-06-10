module Travis
  module Shell

    #
    # Behaviors
    #

    autoload :Helpers, 'travis/shell/helpers'
    autoload :SSH,     'travis/shell/ssh'


    #
    # API
    #

    NEWLINE = "\n"

    # @see Travis::Worker::SSH#execute
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
