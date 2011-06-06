module Travis
  module Shell
    autoload :SSH, 'travis/shell/ssh'

    def exec(*args)
      Travis::Worker.shell.exec(*args)
    end
  end
end

