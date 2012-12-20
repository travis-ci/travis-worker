require "thor"

module Travis
  module Worker
    module Cli
      class Vbox < Thor
        namespace "travis:worker:virtualbox"

        include Cli

        desc 'reset', 'Completely reset Virtualbox'
        method_option :reset,  :aliases => '-r', :type => :boolean, :default => false, :desc => 'Force reset on virtualbox settings and boxes'
        def reset
          return unless reset?
          run <<-sh
            rm -rf ~/.VirtualBox/
            rm -rf ~/Library/VirtualBox/*
            rm -rf ~/VirtualBox\\ VMs/
            rm -rf ~/.vagrant
            rm -rf ~/.vagrant.d
            rm -f  .vagrant

            killall VBoxXPCOMIPCD > /dev/null 2>&1
            killall VBoxSVC       > /dev/null 2>&1
            killall VBoxHeadless  > /dev/null 2>&1
          sh
        end

        protected

          def reset?
            options['reset'] || yes?('Do you really want to completely reset Virtualbox? (All existing VMs will be wiped out.)')
          end
      end
    end
  end
end
