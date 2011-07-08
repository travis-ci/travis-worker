require 'bundler/setup'
require 'travis/worker/cli/app'
require 'travis/worker/cli/development'
require 'travis/worker/cli/vm'
require 'travis/worker/cli/vbox'

$stdout.sync = true

module Travis
  module Worker
    module Cli
      def run(commands)
        normalize_commands(commands).each do |command|
          puts "$ #{command}"
          system command
        end
      end

      def wait(seconds)
        puts "waiting for #{seconds} seconds "
        1.upto(seconds) { putc '.' }
        puts
      end

      def normalize_commands(commands)
        commands = commands.split("\n")
        commands.map! { |command| command.strip }
        commands.reject { |command| command.empty? }
      end
    end
  end
end
