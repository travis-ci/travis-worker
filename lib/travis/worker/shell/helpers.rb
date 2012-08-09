require 'shellwords'
require 'timeout'
require 'filtered_string'

module Travis
  class Worker
    module Shell
      module Helpers
        def export(name, value, options = nil)
          return unless name
          with_timeout("export #{name}=#{value}", 3) do
            execute(*["export #{name}=#{value}", options].compact)
          end
        end

        def export_line(line, options = nil)
          return unless line

          if line =~ /^TRAVIS_/
            options ||= {}
            options[:echo] = false
          end

          secure = line.sub!(/^SECURE /, '')
          filtered = if secure
            ::Travis::Helpers.obfuscate_env_vars(line)
          else
            line
          end

          line = FilteredString.new(line, filtered)
          line = line.mutate("export %s", line)
          line = line.to_s unless secure

          with_timeout(line, 3) do
            execute(*[line, options].compact)
          end
        end

        def chdir(dir)
          execute("mkdir -p #{dir}", :echo => false)
          execute("cd #{dir}")
        end

        def cwd
          evaluate('pwd').to_s.strip
        end

        def file_exists?(filename)
          execute("test -f #{filename}", :echo => false)
        end

        def directory_exists?(dirname)
          execute("test -d #{dirname}", :echo => false)
        end

        # Executes a command within the ssh shell, returning true or false depending
        # if the command succeded.
        #
        # command - The command to be executed.
        # options - Optional Hash options (default: {}):
        #           :stage - The command stage, used to evaluate the timeout.
        #           :echo  - true or false if the command should be echod to the log
        #
        # Returns true if the command completed successfully, false if it failed.
        def execute(command, options = {}, &block)
          with_timeout(command, options[:stage]) do
            command = echoize(command, &block) unless options[:echo] == false
            exec(_unfiltered(command)) { |p, data| buffer << data } == 0
          end
        end

        # Evaluates a command within the ssh shell, returning the command output.
        #
        # command - The command to be evaluated.
        # options - Optional Hash options (default: {}):
        #           :echo - true or false if the command should be echod to the log
        #
        # Returns the output from the command.
        # Raises RuntimeError if the commands exit status is 1
        def evaluate(command, options = {})
          result = ''
          command = echoize(command) if options[:echo]
          status = exec(command) do |p, data|
            result << data
            buffer << data if options[:echo]
          end
          raise("command '#{command}' failed: '#{result}'") unless status == 0
          result
        end

        def echo(output, options = {})
          options[:force] ? buffer.send(:concat, output) : buffer << output
        end

        def terminate(message)
          execute("sudo shutdown -n now #{message}")
        end

        # Formats a shell command to be echod and executed by a ssh session.
        #
        # cmd - command to format.
        #
        # Returns the cmd formatted.
        def echoize(cmd, options = {})
          commands = [cmd].flatten.map { |cmd| cmd.respond_to?(:split) ? cmd.split("\n") : cmd }
          commands.flatten.map do |cmd|
            echo = block_given? ? yield(cmd) : cmd
            "echo #{Shellwords.escape("$ #{echo}")}\n#{_unfiltered(cmd)}"
          end.join("\n")
        end

        # Formats a shell command to be echod and executed by a ssh session.
        #
        # cmd - command to format.
        #
        # Returns the cmd formatted.
        def parse_cmd(cmd)
          cmd.match(/^(\S+=\S+ )*(.*)/).to_a[1..-1].map { |token| token.strip if token }
        end

        def with_timeout(command, stage, &block)
          seconds = timeout(stage)
          begin
            Timeout.timeout(seconds, &block)
          rescue Timeout::Error => e
            raise Travis::Build::CommandTimeout.new(stage, command, seconds)
          end
        end

        def timeout(stage)
          if stage.is_a?(Numeric)
            stage
          else
            config.timeouts[stage || :default]
          end
        end

        def _unfiltered(str)
          str = str.respond_to?(:unfiltered) ? str.unfiltered : str.to_s
        end
        private :_unfiltered
      end
    end
  end
end
