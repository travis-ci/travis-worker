require "thor"

module Travis
  module Worker
    module Cli
      class Vbox < Thor
        namespace "travis:worker:virtualbox"

        include Cli

        desc 'reset', 'Completely reset Virtualbox'
        def reset
          if yes? 'Do you really want to completely reset Virtualbox? (All existing VMs will be wiped out.)'
            run <<-sh
              rm -rf ~/.VirtualBox/
              rm -rf ~/VirtualBox\\ VMs/
              rm -rf ~/.vagrant
              rm -f  .vagrant

              killall VBoxXPCOMIPCD > /dev/null 2>&1
              killall VBoxSVC       > /dev/null 2>&1
              killall VBoxHeadless  > /dev/null 2>&1
            sh
          end
        end
      end
    end
  end
end
