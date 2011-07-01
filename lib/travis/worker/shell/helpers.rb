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
          vars, cmd = parse_cmd(cmd)
          options = options[:timeout] ? "-t #{options[:timeout]}" : nil
          [vars, 'timetrap', options, cmd].compact.join(' ')
        end

        def parse_cmd(cmd)
          cmd.match(/^(\S+=\S+ )*(.*)/).to_a[1..-1].map { |token| token.strip if token }
        end
      end # Helpers
    end # Shell
  end # Worker
end # Travis
