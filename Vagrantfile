require 'yaml'

DEFAULTS = {
  'count' => 1,
  'base' => 'lucid32',
  'memory' => 1536,
  'cookbooks' => 'vendor/cookbooks',
  'log_level' => 'info'
}

module Travis
  class Config < Hash
    DEFAULTS.keys.each do |key|
      define_method(key) do
        ENV.fetch("WORKER_#{key.upcase}", DEFAULTS[key] || self[key])
      end
    end

    def initialize(config)
      self.replace(config)
    end

    def vms
      ['base'] + (1..count.to_i).map { |num| "worker-#{num}" }
    end

    def recipes?
      recipes && !recipes.empty?
    end
  end
end

config = Travis::Config.new(YAML.load_file('.vms.yml'))


Vagrant::Config.run do |c|
  config.vms.each_with_index do |name, num|

    c.vm.define(name) do |c|
      c.vm.box = name == 'base' ? config.base : 'base'
      c.vm.forward_port('ssh', 22, 2220 + num)

      c.vm.customize do |vm|
        vm.memory_size = memory.to_i
      end

      if config.recipes?
        c.vm.provision :chef_solo do |chef|
          chef.cookbooks_path = config.cookbooks
          chef.log_level = config.log_level

          config.recipes.each do |recipe|
            chef.add_recipe(recipe)
          end

          chef.json.merge!(config.json || {})
        end
      end
    end
  end
end
