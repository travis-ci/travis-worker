$: << 'lib'
require 'yaml'
require 'travis/worker'

config = Travis::Worker.config.vms

Vagrant::Config.run do |c|
  config.names.each_with_index do |name, num|
    c.vm.define(name) do |box|
      box.vm.box = Travis::Worker.config.env
      box.vm.forward_port('ssh', 22, 2220 + num)
    end
  end
end
