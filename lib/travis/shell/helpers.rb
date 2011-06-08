require 'shellwords'

module Travis
  module Shell
    module Helpers
      def echoize(cmd)
        cmd = [cmd].flatten.join("\n").split("\n")
        cmd.map { |cmd| "echo #{Shellwords.escape("$ #{cmd}")}\n#{cmd}" }.join("\n")
      end
    end
  end
end
