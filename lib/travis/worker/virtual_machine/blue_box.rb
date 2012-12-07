require 'fog'
require 'shellwords'
require 'digest/sha1'
require 'benchmark'
require 'travis/support'
require 'travis/worker/shell'

module Travis
  module Worker
    module VirtualMachine
      # A simple encapsulation of the BlueBox commands used in the
      # Travis Virtual Machine lifecycle.
      class BlueBox
        include Retryable, Logging

        BLUE_BOX_VM_DEFAULTS = {
          :username  => 'travis',
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

          opts = BLUE_BOX_VM_DEFAULTS.merge(opts.merge(:image_id => latest_template['id'], :hostname => "#{Travis::Worker.config.env}-#{name}"))

          retryable(:tries => 5) do
            destroy_duplicate_server(opts[:hostname])
            Timeout.timeout(240) do
              begin
                @password = (opts[:password] ||= generate_password)

                @server = connection.servers.create(opts)
                
                info "Provisioning a BlueBox VM"
                time = Benchmark.realtime { @server.wait_for { ready? } }
                info "BlueBox VM provisioned in #{time.round(2)} seconds"
              rescue Exception => e
                error "BlueBox VM would not boot within 180 seconds"
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

        def latest_template
          @latest_template ||= begin
            templates = connection.get_templates.body
            templates = templates.find_all { |t| t['public'] == false && t['description'] =~ /^travis-#{image_type}/ }
            templates.sort { |a, b| b['created'] <=> a['created'] }.first
          end
        end

        def image_type
          Travis::Worker.config.blue_box.image_type
        end

        def destroy_server(opts = {})
          destroy_vm(server)
          @server = nil
          @shell = nil
        end
        
        def destroy_duplicate_server(hostname)
          server = connection.servers.detect do |server|
            name = server.hostname.split('.').first
            name == hostname
          end
          destroy_vm(server) if server
        end

        def prepare
          info "using latest template '#{latest_template['description']}' (#{latest_template['id']})"
        end

        private
        
          def destroy_vm(vm)
            debug "vm is in #{vm.state} state"
            info "destroying the VM"
            vm.destroy
          rescue Fog::Compute::Bluebox::NotFound => e
            info "went to destroy the VM but it didn't exist :/"
          rescue Excon::Errors::InternalServerError => e
            info "went to destroy the VM but there was an internal server error"
            log_exception(e)
          end

          def generate_password
            Digest::SHA1.base64digest(OpenSSL::Random.random_bytes(30))[0..19]
          end

      end
    end
  end
end
