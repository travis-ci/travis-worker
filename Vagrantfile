$: << 'lib'
require 'yaml'
require 'travis/worker'

config = Travis::Worker::Vagrant::Config.new(YAML.load_file('.vms.yml'))

Vagrant::Config.run do |c|
  config.vms.each_with_index do |name, num|

    c.vm.define(name) do |c|
      c.vm.box = name
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

