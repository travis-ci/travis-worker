require 'travis/support'
require 'travis/worker/ssh/session'

module Travis
  module Worker
    module VirtualMachine
      class StaticMachine
        include Logging

        class << self
          def vm_count
            Travis::Worker.config.vms.count
          end

          def vm_names
            vm_count.times.map { |num| "#{Travis::Worker.config.vms.name_prefix}-#{num + 1}" }
          end
        end

        log_header { "#{name}:worker:virtual_machine:static_machine" }

        attr_reader :name, :ip

        def initialize(name)
          @name = name
        end

        def prepare
          info "static_machine API adapter prepared"
        end

        def sandboxed(opts = {})
          create_server(opts)
          yield
        ensure
          session.close if @session
          destroy_server(opts)
        end

        def create_server(opts = {})
          @ips = Array(Travis::Worker.config.static_machine.ip)
          raise "The static_machine provider requires the static_machine.ip field in config file!" unless @ips
          raise "Defined count of static_machine.ip differ form vms.count" if @ips.size != Travis::Worker.config.vms.count
        end

        def destroy_server(opts = {})
          @session = nil
        end

        def session
          #create_server unless clone
          @session ||= Ssh::Session.new(name,
            :host => ip_address,
            :port => Travis::Worker.config.static_machine.port || 22,
            :username => Travis::Worker.config.static_machine.username,
            :private_key_path => Travis::Worker.config.static_machine.private_key_path,
            :buffer => Travis::Worker.config.shell.buffer,
            :timeouts => Travis::Worker.config.timeouts,
          )
        end

        def full_name
          "#{Travis::Worker.config.host}:travis-#{name}-#{ip}"
        end

        private

          def worker_number
            /\w+-(\d+)/.match(name)[1].to_i
          end

          def ip_address
            @ips[worker_number - 1]
          end


      end
    end
  end
end
