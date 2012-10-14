require 'active_support/inflector'

module Travis
  module Worker
    module VirtualMachine
      class VmNotFound   < StandardError; end
      class VmFatalError < StandardError; end

      def self.provider
        @provider ||= begin
          provider = Travis::Worker.config.vms.provider
          provider_name = provider.camelize

          require "travis/worker/virtual_machine/#{provider}"

          self.const_get(provider_name)
        end
      end
    end
  end
end
