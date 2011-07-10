module Travis
  module Worker
    module Vagrant
      autoload :Config, 'travis/worker/vagrant/config'

      class << self
        def config
          @config ||= Config.new(YAML.load_file('.vms.yml'))
        end
      end
    end
  end
end


