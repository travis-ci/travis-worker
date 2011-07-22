require 'thor'
require 'fileutils'
require 'travis/worker'

module Travis
  module Worker
    module Cli
      class Resque < Thor
        class << self
          def config
            Travis::Worker.config.vms
          end
        end

        namespace "travis:worker:resque"

        include Cli

        desc 'start', 'Start god and workers'
        def start
          if running?
            puts "God seems to be running."
          else
            run 'god -c config/worker.god'
            wait_for :pid_files
          end
        end

        desc 'stop', 'Stop god and workers'
        method_option :graceful, :type => :boolean, :default => true, :desc => 'Wait for current jobs to be finished'
        method_option :timeout,  :type => :numeric, :default => 30,   :desc => 'Time out after n seconds'
        method_option :force,    :type => :boolean, :default => true, :desc => 'Whether or not to force termination after timeout'
        method_option :pids,     :type => :boolean, :default => true, :desc => 'Remove pid files'

        def stop
          if !running?
            puts "God does not seem to be running."
            return
          elsif options['graceful']
            run 'god signal workers USR2'
            wait_for :workers_paused, :timeout => false
          end
          run 'god terminate'
          kill unless wait_for :workers_gone
          remove_pids if remove_pids?
        end

        desc 'kill', 'Forcefully kill all workers'
        method_option :pids, :type => :boolean, :default => true, :desc => 'Remove pid files'

        def kill
          if pid_files?
            puts "Forcefully killing workers ..."
            pids.each { |pid| run "kill -9 #{pid}" }
            remove_pids if remove_pids?
          else
            puts "No pids found, nothing to kill."
          end
        end

        protected

          def running?
            `ps ax` =~ /bin\/god /
          end

          def wait_for(condition, options = {})
            started = Time.now
            print "\nWaiting for: #{condition.inspect} "
            loop do
              if is?(condition)
                puts "\nOk.\n\n"
                break true
              elsif timeout?(started, options)
                puts "\nTimed out after #{timeout(options)} seconds waiting for #{condition.inspect}.\n\n"
                break false
              end
              wait
            end
          end

          def wait
            sleep(1)
            putc('.')
          end

          def is?(condition)
            send(:"#{condition}?")
          end

          def workers_paused?
            pids.all? { |pid| `ps #{pid}` =~ /Paused/ }
          end

          def workers_gone?
            pids.all? { |pid| `ps #{pid}` !~ /resque(:work|-[\d\.])/ }
          end

          def timeout(options)
            options.key?(:timeout) ? options[:timeout] : self.options['timeout'] || 20
          end

          def timeout?(started, options = {})
            timeout(options) == false ? false : Time.now - started > timeout(options)
          end

          def pid_files?
            !pid_files.empty?
          end

          def pid_files
            Dir[File.expand_path('~/.god/pids/*')]
          end

          def pids
            pid_files.map { |pid_file| File.read(pid_file) }
          end

          def remove_pids
            puts "Removing pid files."
            pid_files.each { |pid_file| FileUtils.rm(pid_file) }
          end

          def remove_pids?
            options['pids']
          end
      end
    end
  end
end

