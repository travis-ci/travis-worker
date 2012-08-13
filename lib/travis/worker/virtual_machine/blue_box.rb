require 'fog'
require 'shellwords'
require 'digest/sha1'
require 'travis/support'

module Travis
  class Worker
    module VirtualMachine
      # A simple encapsulation of the BlueBox commands used in the
      # Travis Virtual Machine lifecycle.
      class BlueBox
        include Retryable, Logging

        BLUE_BOX_VM_DEFAULTS = {
          :username  => 'travis',
          :image_id  => Travis::Worker.config.blue_box.image_id,
          :flavor_id => Travis::Worker.config.blue_box.flavor_id,
          :location_id => Travis::Worker.config.blue_box.location_id
        }

        class << self
          def vm_count
            Travis::Worker.config.vms.count
          end

          def vm_names
            vm_count.times.map { |num| "#{Travis::Worker.config.vms.name_prefix}-#{num + 1}" }
          end
        end

        log_header { "#{name}:worker:virtual_machine:blue_box" }

        attr_reader :name, :password, :server

        def initialize(name)
          @name = name
        end

        # create a connection
        def connection
          @connection ||= Fog::Compute.new(
            :provider            => 'Bluebox',
            :bluebox_customer_id => Travis::Worker.config.blue_box.customer_id,
            :bluebox_api_key     => Travis::Worker.config.blue_box.api_key
          )
        end

        def create_server(opts = {})
          return @server if server

          info "provisioning a VM on BlueBox"

          opts = defaults.merge(BLUE_BOX_VM_DEFAULTS)

          retryable(:tries => 3) do
            Timeout.timeout(65) do
              begin
                @password = (opts[:password] ||= generate_password)

                @server = connection.servers.create(defaults.merge(opts))
                @server.wait_for { ready? }
              rescue Exception => e
                info "BlueBox VM would not boot"
                raise
              end
            end
          end

          @server
        end

        def shell
          create_server unless server
          @shell ||= Shell::Session.new(name,
            :host => ip_address,
            :port => 22,
            :username => 'travis',
            :password => password,
            :buffer => Travis::Worker.config.shell.buffer,
            :timeouts => Travis::Worker.config.timeouts
          )
        end

        def sandboxed
          create_server
          yield
        rescue Exception => e
          log_exception(e)
          { :result => 1 }
        ensure
          destroy_server
        end

        def full_name
          "#{Travis::Worker.config.host}:travis-#{name}"
        end

        def ip_address
          server.ips.first['address']
        end

        def destroy_server
          debug "vm is in #{server.state} state"
          if server_destroyable?
            info "destroying the VM"
            server.destroy
            @server = nil
            @shell = nil
          end
        rescue Fog::Compute::Bluebox::NotFound => e
          info "went to destroy the VM but it didn't exist :/"
        rescue Excon::Errors::InternalServerError => e
          info "went to destroy the VM but there was an internal server error"
          log_exception(e)
        end

        def prepare
          true
        end

        private

          def server_destroyable?
            if server
              ['running', 'error'].include?(server.state)
            else
              false
            end
          end

          def generate_password
            "#{random_string}:travis:#{random_string}"
          end

          def random_string
            chars = ('A'...'z').to_a.select { |c| c =~ /\w+/ }
            (0...10).map{ chars[rand(chars.size)] }.join
          end

      end
    end
  end
end
