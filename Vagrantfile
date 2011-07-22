$: << 'lib'
require 'yaml'
require 'travis/worker'

config = Travis::Worker.config.vms
with_base = ENV['WITH_BASE'] == 'true'

Vagrant::Config.run do |c|
  config.names.each_with_index do |name, num|
    next if name == 'base' && !with_base

    c.vm.define(name) do |c|
      c.vm.box = name == 'base' ? 'base' : "worker-#{num}"
      c.vm.forward_port('ssh', 22, 2220 + num)

      c.vm.customize do |vm|
        vm.memory_size = config.memory.to_i
      end

      if config.recipes?
        c.vm.provision :chef_solo do |chef|
          chef.cookbooks_path = config.cookbooks
          chef.log_level = :debug # config.log_level

          config.recipes.each do |recipe|
            chef.add_recipe(recipe)
          end

          chef.json.merge!(config.json)
        end
      end
    end
  end
end

