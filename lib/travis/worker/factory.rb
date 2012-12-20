require 'travis/worker/instance'
require 'travis/worker/virtual_machine'

module Travis
  module Worker
    class Factory
      attr_reader :name, :config, :broker_connection

      def initialize(name, config = nil, broker_connection = nil)
        @name              = name
        @config            = config
        @broker_connection = broker_connection
      end

      def worker
        Instance.new(name, vm, broker_connection, queue_name, config)
      end

      def vm
        VirtualMachine.provider.new(name)
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
