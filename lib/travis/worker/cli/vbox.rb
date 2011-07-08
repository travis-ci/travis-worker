require "thor"

module Travis
  module Worker
    module Cli
      class Vbox < Thor
        include Cli

        desc 'reset', 'Completely reset Virtualbox'
        def reset
          if yes? 'Do you really want to completely reset Virtualbox? (All existing VMs will be wiped out.)'
            run <<-sh
              rm -rf ~/.VirtualBox/
              rm -rf ~/VirtualBox\ VMs/
              rm -rf ~/.vagrant
              rm .vagrant

              killall VBoxXPCOMIPCD
              killall VBoxSVC
              killall VBoxHeadless
            sh
          end
        end
      end
    end
  end
end
