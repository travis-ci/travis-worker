require 'travis/worker/cli/app'
require 'travis/worker/cli/console'
require 'travis/worker/cli/development' if defined?(JRUBY_VERSION)
require 'travis/worker/cli/vagrant'
require 'travis/worker/cli/virtualbox'

$stdout.sync = true

module Travis
  module Worker
    module Cli
      def run(*commands)
        normalize_commands(commands).each do |command|
          puts "$ #{command}"
          return false unless system(command)
        end
        true
      end

      def wait(seconds)
        puts "waiting for #{seconds} seconds "
        1.upto(seconds) { putc '.' }
        puts
      end

      def normalize_commands(commands)
        commands = commands.join("\n").split("\n")
        commands.map! { |command| command.strip }
        commands.reject { |command| command.empty? }
      end
    end
  end
end
