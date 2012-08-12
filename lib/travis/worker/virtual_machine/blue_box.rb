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

        class << self
          def vm_count
            Travis::Worker.config.vms.count
          end

          def vm_names
            vm_count.times.map { |num| "#{Travis::Worker.config.vms.name_prefix}-#{num + 1}" }
          end
        end

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

          defaults = {
            :username  => 'travis',
            :image_id  => Travis::Worker.config.blue_box.image_id,
            :flavor_id => Travis::Worker.config.blue_box.flavor_id,
            :location_id => Travis::Worker.config.blue_box.location_id
          }
          opts = defaults.merge(opts)

          @password = (opts[:password] ||= generate_password)

          @server = connection.servers.create(defaults.merge(opts))
          @server.wait_for { ready? }
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
          "#{Travis::Worker.config.host}:#{name}"
        end

        def logging_header
          name
        end

        def ip_address
          server.ips.first['address']
        end

        def destroy_server
          if server_destroyable?
            info "destroying the VM"
            server.destroy
          end
        rescue Fog::Compute::Bluebox::NotFound => e
          info "went to destroy the VM but it didn't exist :/"
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
            '!%@$#' + Digest::SHA1.hexdigest("travis-#{Time.now.to_i}")[0..20] + '!%@$#'
          end

      end
    end
  end
end
