require 'yaml'

defaults = {
  'count' => 1,
  'base' => 'lucid32',
  'memory' => 1536,
  'cookbooks' => 'vendor/cookbooks',
  'log_level' => 'info'
}
env = defaults.keys.inject({}) { |env, key| env[key] = ENV["WORKER_#{key.upcase}"] if ENV.key?("WORKER_#{key.upcase}"); env }
config = defaults.merge(YAML.load_file('.vms.yml')).merge(env)

# extract to local vars
keys = %w(count base memory cookbooks log_level)
count, base, memory, cookbooks, log_level, recipes, json = config.values_at(*keys)

vms = ['base'] + (1..count.to_i).map { |num| "worker-#{num}" }

Vagrant::Config.run do |c|
  vms.each_with_index do |name, num|

    c.vm.define(name) do |c|
      c.vm.box = name == 'base' ? base : 'base'
      c.vm.forward_port('ssh', 22, 2220 + num)

      c.vm.customize do |vm|
        vm.memory_size = memory.to_i
      end

      if recipes && !recipes.empty?
        c.vm.provision :chef_solo do |chef|
          chef.cookbooks_path = cookbooks
          chef.log_level = log_level.to_sym

          recipes.each do |recipe|
            chef.add_recipe(recipe)
          end

          chef.json.merge!(json || {})
        end
      end
    end
  end
end
