$: << 'lib'
require 'yaml'
require 'travis/worker'

config = Travis::Worker.config.vms

Vagrant::Config.run do |c|
  config.names.each_with_index do |name, num|
    c.vm.define(name) do |box|
      box.vm.box = Travis::Worker.config.env
      box.vm.forward_port('ssh', 22, 2220 + num)

      box.vm.customize do |vm|
        vm.memory_size = config.memory.to_i
      end

      if config.provision?
        box.vm.provision :chef_solo do |chef|
          chef.cookbooks_path = config.cookbooks
          chef.log_level = :debug

          config.recipes.each do |recipe|
            chef.add_recipe(recipe)
          end

          chef.json.merge!(config.json)
        end
      end
    end
  end
end
