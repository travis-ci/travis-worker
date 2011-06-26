require 'shellwords'

module Travis
  module Worker
    module Shell
      module Helpers
        def echoize(cmd)
          [cmd].flatten.join("\n").split("\n").map { |cmd| "echo #{Shellwords.escape("$ #{cmd}")}\n#{cmd}" }.join("\n")
        end
      end # Helpers
    end # Shell
  end # Worker
end # Travis
