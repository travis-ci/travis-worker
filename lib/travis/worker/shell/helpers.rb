require 'shellwords'

module Travis
  module Worker
    module Shell
      module Helpers
        def echoize(cmd, options = {})
          [cmd].flatten.join("\n").split("\n").map do |cmd|
            "echo #{Shellwords.escape("$ #{cmd.gsub(/timetrap (?:-t \d* )?/, '')}")}\n#{cmd}"
          end.join("\n")
        end

        def timetrap(cmd, options = {})
          options[:timeout] ? "timetrap -t #{options[:timeout]} #{cmd}" : "timetrap #{cmd}"
        end
      end # Helpers
    end # Shell
  end # Worker
end # Travis
