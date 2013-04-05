require 'travis/worker/instance'
require 'travis/worker/virtual_machine_pool'

module Travis
  module Worker
    class Factory
      attr_reader :name, :config, :vm_pool, :broker_connection

      def initialize(name, vm_pool, config = nil, broker_connection = nil)
        @name              = name
        @vm_pool           = vm_pool
        @config            = config
        @broker_connection = broker_connection
      end

      def worker
        Instance.new(name, vm_pool, broker_connection, queue_name, config)
      end

      def queue_name
        config[:queue]
      end

      def config
        @config ||= Travis::Worker.config
      end
    end
  end
end
