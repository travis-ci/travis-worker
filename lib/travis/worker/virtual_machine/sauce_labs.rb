require 'travis-saucelabs-api'
require 'shellwords'
require 'digest/sha1'
require 'benchmark'
require 'travis/support'
require 'travis/worker/ssh/session'
require 'celluloid'

module Travis
  module Worker
    module VirtualMachine
      class SauceLabs
        include Retryable
        include Logging
        include Celluloid

        class << self
          def vm_count
            Travis::Worker.config.vms.count
          end

          def vm_names
            vm_count.times.map { |num| "#{Travis::Worker.config.vms.name_prefix}-#{num + 1}" }
          end
        end

        log_header { "#{name}:worker:virtual_machine:sauce_labs" }

        attr_reader :name, :password, :server, :running, :ready

        def initialize(name)
          @name = name
          @running = false
          @ready = false
        end

        def connection
          @connection ||= Travis::SaucelabsAPI.new(Travis::Worker.config.sauce_labs.api_endpoint)
        end

        def create_server(opts = {})
          return if @running
          prefix = Worker.config.host.split('.').first
          hostname = "testing-#{prefix}-#{Process.pid}-#{name}"
          @running = true

          retryable(:tries => 3) do
            destroy_duplicate_server(hostname)
            Timeout.timeout(180) do
              instance_id = nil
              begin
                @password = generate_password
                startup_info = { :password => @password, :hostname => hostname }
                instance_id = connection.start_instance(startup_info)['instance_id']
                @server = connection.instance_info(instance_id)
                connection.allow_outgoing(instance_id)
                async.instrument { wait_for { vm_ready?(@server) }; @ready = true }
              rescue Exception => e
                connection.kill_instance(instance_id) if instance_id
                error 'SauceLabs VM would not boot within 180 seconds'
                raise
              end
            end
          end
        end

        def session
          create_server unless server
          wait_for { vm_ready?(@server) }
          @session ||= Ssh::Session.new(name,
            :host => ip_address,
            :port => 3422,
            :username => 'travis',
            :password => password,
            :buffer => Travis::Worker.config.shell.buffer,
            :timeouts => Travis::Worker.config.timeouts,
            :platform => :osx,
          )
        end

        def sandboxed(opts={})
          create_server(opts) unless server
          yield
        ensure
          session.close
          destroy_server
        end

        def full_name
          "#{Travis::Worker.config.host}:travis-#{name}"
        end

        def ip_address
          @server['private_ip']
        end

        def destroy_server(opts = {})
          return unless server
          destroy_vm(server)
          @server = nil
          @session = nil
          @running = false
          @ready = false
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

        def check_connection
          server && vm_ready?(server)
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
          connection.kill_instance(vm['instance_id'])
        end

        def generate_password
          Digest::SHA1.base64digest(OpenSSL::Random.random_bytes(30)).gsub(/[\&\+\/\=\\]/, '')[0..19]
        end

        def wait_for(&block)
          sleep 1.0 until yield
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

