$: << 'lib'
require 'yaml'
require 'bundle/setup'
require 'travis/worker'

config = Travis::Worker.config.vms

Vagrant::Config.run do |c|
  config.names.each_with_index do |name, num|
    c.vm.define(name) do |box|
      box.vm.box = config.name_prefix
      box.vm.forward_port('ssh', 22, 2220 + num + 1)

      box.vm.customize do |vm|
        vm.name = name
      end
    end
  end
end
