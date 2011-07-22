require 'thor'
require 'yaml'
require 'json'
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

        desc 'terminate', 'Terminate god and workers'
        method_option :graceful, :type => :boolean, :default => true, :desc => 'Wait for current jobs to be finished'
        method_option :timeout,  :type => :numeric, :default => 30,   :desc => 'Time out after n seconds'
        method_option :force,    :type => :boolean, :default => true, :desc => 'Whether or not to force termination after timeout'

        def terminate
          if options['graceful']
            run 'god signal workers USR2'
            wait_for :workers_waiting
          end
          run 'god terminate'
          kill unless wait_for :workers_gone
        end

        desc 'kill', 'Forcefully kill all workers'
        method_option :pids, :type => :boolean, :default => true, :desc => 'Remove pid files'

        def kill
          pids = Dir[File.expand_path('~/.god/pids/*')]
          if pids.empty?
            puts "No pids found, nothing to kill."
          else
            puts "Forcefully killing workers ..."
            pids.each do |pid|
              run "kill -9 #{File.read(pid)}"
              run "rm #{pid}" if remove_pids?
             end
          end
        end

        protected

          CONDITIONS = {
            :workers_waiting => lambda { `ps x` !~ /Waiting for builds/ },
            :workers_gone    => lambda { `ps x` !~ /resque(:work|-[\d\.])/ }
          }

          def wait_for(condition)
            started = Time.now
            print "\nWaiting for: #{condition.inspect} "
            loop do
              if is?(condition)
                puts "\nOk, all #{condition.to_s.gsub('_', ' ')}.\n\n"
                break true
              elsif timeout?(started)
                puts "\nTimed out after #{options['timeout']}.\n\n"
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
            CONDITIONS[condition].call
          end

          def timeout?(started)
            Time.now - started > options['timeout']
          end

          def remove_pids?
            options['pids']
          end
      end
    end
  end
end

