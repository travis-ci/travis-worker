require 'travis-saucelabs-api'
require 'shellwords'
require 'benchmark'
require 'travis/support'
require 'travis/worker/ssh/session'
require "fog"

module Travis
  module Worker
    module VirtualMachine
      class SauceLabs
        include Retryable
        include Logging

        class << self
          def vm_count
            Travis::Worker.config.vms.count
          end

          def vm_names
            vm_count.times.map { |num| "#{Travis::Worker.config.vms.name_prefix}-#{num + 1}" }
          end
        end

        log_header { "#{name}:worker:virtual_machine:sauce_labs" }

        attr_reader :name, :server

        def initialize(name)
          @name = name
        end

        def connection
          @connection ||= Travis::SaucelabsAPI.new(Travis::Worker.config.sauce_labs.api_endpoint)
        end

        def create_server(opts = {})
          retryable(:tries => 3) do
            destroy_duplicate_server(hostname)
            create_new_server
          end
        end

        def create_new_server
          @server = start_server
          info "Booting #{hostname} (#{ip_address})"
          instrument do
            Fog.wait_for(240, 3) do
              vm_ready?(@server)
            end
          end
        rescue Timeout::Error, Fog::Errors::TimeoutError => e
          if @server
            error "Sauce Labs VM would not boot within 240 seconds: id=#{@server["instance_id"]}"
          end
          Metriks.meter("worker.vm.provider.saucelabs.boot.timeout").mark
          raise
        rescue StandardError => e
          Metriks.meter("worker.vm.provider.saucelabs.boot.error").mark
          error "Booting a Sauce Labs VM failed without the following error: #{e.inspect}"
          raise
        end

        def session
          create_server unless server
          @session ||= Ssh::Session.new(name,
            :host => ip_address,
            :port => 3422,
            :username => 'travis',
            :private_key_path => Travis::Worker.config.sauce_labs.private_key_path,
            :password => Travis::Worker.config.sauce_labs.private_key_passphrase,
            :buffer => Travis::Worker.config.shell.buffer,
            :timeouts => Travis::Worker.config.timeouts,
            :platform => :osx,
          )
        end

        def sandboxed(opts={})
          create_server(opts)
          yield
        ensure
          session.close
          destroy_server
        end

        def full_name
          "#{Travis::Worker.config.host}:travis-#{name}"
        end

        def hostname
          @hostname ||= "testing-#{Worker.config.host.split(".").first}-#{Process.pid}-#{name}"
        end

        def ip_address
          @server['private_ip']
        end

        def start_server
          instance_id = connection.start_instance({ hostname: hostname }, 'ichef-osx8-10.8-travis')['instance_id']
          connection.allow_outgoing(instance_id)
          connection.allow_incoming(instance_id, "0.0.0.0/0", 3422)

          connection.instance_info(instance_id)
        end

        def destroy_server(opts = {})
          destroy_vm(server)
        ensure
          @server = nil
          @session = nil
        end

        def destroy_duplicate_server(hostname)
          instance_ids = connection.list_instances['instances']
          instances = instance_ids.map { |instance_id| connection.instance_info(instance_id) }
          instance = instances.detect do |instance|
            name = instance['extra_info']['hostname'] if instance && instance['extra_info']
            name == hostname
          end

          destroy_vm(instance) if instance
        end

        def prepare
          info "Sauce Labs API adapter prepared"
        end

        private

        def instrument
          info "Provisioning a Sauce Labs VM"
          time = Benchmark.realtime { yield }
          info "SauceLabs VM provisioned in #{time.round(2)} seconds"
          Metriks.timer('worker.vm.provider.saucelabs.boot').update(time)
        end

        def destroy_vm(vm)
          info "destroying the VM"
          retryable(tries: 3) do
            connection.kill_instance(vm['instance_id'])
          end
        end

        def vm_ready?(vm)
          socket = TCPSocket.new(vm['private_ip'], 3422)
          true
        rescue StandardError
          false
        ensure
          socket.close if socket
        end
      end
    end
  end
end
