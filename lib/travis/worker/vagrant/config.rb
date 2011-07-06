module Travis
  module Worker
    module Vagrant
      class Config < Hash
        DEFAULTS = {
          'count' => 1,
          'base' => 'lucid32',
          'memory' => 1536,
          'cookbooks' => 'vendor/cookbooks',
          'log_level' => 'info'
        }

        DEFAULTS.keys.each do |key|
          define_method(key) do
            ENV.fetch("WORKER_#{key.upcase}", self[key] || DEFAULTS[key])
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

        def recipes
          self['recipes']
        end

        def json
          self['json'] || {}
        end
      end
    end
  end
end


