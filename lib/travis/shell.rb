module Travis
  module Shell
    autoload :Helpers, 'travis/shell/helpers'
    autoload :SSH,     'travis/shell/ssh'

    def exec(*args)
      Travis::Worker.shell.execute(*args)
    end

    def echoize(cmd)
      cmd = [cmd].flatten.join("\n").split("\n")
      cmd.map { |cmd| "echo #{Shellwords.escape("$ #{cmd}")}\n#{cmd}" }.join("\n")
    end
  end
end

