require 'travis-saucelabs-api'
require 'shellwords'
require 'benchmark'
require 'travis/support'
require 'travis/worker/ssh/session'
require "fog"
require 'net/vnc'

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

        def prepare
          info "Sauce Labs API adapter prepared"
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
            :keychain_password => Travis::Worker.config.keychain_password[@vm_image],
          )
        end

        def sandboxed(opts={})
          create_server(opts)
          upload_wrapper_script_and_run
          yield
        ensure
          session.close if @session
          destroy_server
        end

        def full_name
          "#{Travis::Worker.config.host}:travis-#{name}"
        end

        private

        def upload_wrapper_script_and_run
          extra = @server["extra_info"]
          vnc_host = extra["handlanger_host"]
          vnc_port = extra["handlanger_vnc_port"].to_i
          session.upload_file("~/proxy_build.rb", <<EOF)
#!/usr/bin/env ruby

require "open3"
require "socket"

server = TCPServer.new("127.0.0.1", 15782)
socket = server.accept

Open3.popen2e("/bin/bash", "--login", "~/build.sh") do |stdin, stdouterr, wait_thr|
  until stdouterr.eof?
    socket.print(stdouterr.read(1))
  end

  wait_thr.join
end

socket.close
EOF
          session.exec("chmod +x ~/proxy_build.rb")

          Net::VNC.open("#{vnc_host}:#{vnc_port-5900}") do |vnc|
            # Open Spotlight
            vnc.key_press(:left_super, " ")
            sleep 1

            # Open Terminal.app
            'terminal.app'.split(//).each { |char| vnc.key_press(char); sleep 0.1 }
            vnc.key_press(:return)

            sleep 1

            # Enter ~/proxy_build.rb
            vnc.key_press(:left_shift, '`'); sleep 0.1
            '/proxy_build.rb'.split(//).each { |char| vnc.key_press(char); sleep 0.1 }
            vnc.key_press(:return)
            sleep 2
          end
        end

        def api
          @api ||= Travis::SaucelabsAPI.new(Travis::Worker.config.sauce_labs.api_endpoint)
        end

        def create_server(opts = {})
          retryable(:tries => 3) do
            destroy_duplicate_server(hostname)
            create_new_server(opts)
          end
        end

        def create_new_server(opts)
          @server = start_server(opts)
          extra = @server["extra_info"]
          vnc_port = extra["handlanger_vnc_port"]
          vnc_host = extra["handlanger_host"]
          info "Booting #{hostname} (#{ip_address}), #{@server["instance_id"]}, jfvnc://minion1.travis.miso:#{vnc_port}?securitytype=SSH&hosttype=Mac&sshoptions=-lhenrik%20-L#{vnc_port}:#{vnc_host}:#{vnc_port}%20-p3422"
          instrument do
            Fog.wait_for(240, 3) do
              vm_ready?(@server)
            end
          end
        rescue Timeout::Error, Fog::Errors::TimeoutError
          if @server
            error "Sauce Labs VM would not boot within 240 seconds: id=#{@server["instance_id"]}"
          end
          Metriks.meter("worker.vm.provider.saucelabs.boot.timeout").mark
          raise
        rescue  => e
          Metriks.meter("worker.vm.provider.saucelabs.boot.error").mark
          error "Booting a Sauce Labs VM failed with the following error: #{e.inspect}"
          raise
        end

        def hostname
          @hostname ||= "testing-#{Worker.config.host.split(".").first}-#{Process.pid}-#{name}"
        end

        def ip_address
          @server['private_ip']
        end

        def start_server(opts)
          image_name = opts[:custom_image] || 'default'
          @vm_image = Travis::Worker.config.image_mappings[image_name] || Travis::Worker.config.image_mappings.default

          instance_id = api.start_instance({ hostname: hostname }, @vm_image)['instance_id']
          api.instance_info(instance_id)
        end

        def destroy_server(opts = {})
          destroy_vm(server) if @server
        ensure
          @server = nil
          @session = nil
        end

        def destroy_duplicate_server(hostname)
          instance_ids = api.list_instances['instances']
          instances = instance_ids.map { |instance_id| api.instance_info(instance_id) }
          instances = instances.compact.select do |instance|
            name = instance['extra_info']['hostname'] if instance['extra_info']
            name == hostname
          end

          instances.each { |instance| destroy_vm(instance) }
        end

        def instrument
          info "Provisioning a Sauce Labs VM"
          time = Benchmark.realtime { yield }
          info "SauceLabs VM provisioned in #{time.round(2)} seconds"
          Metriks.timer('worker.vm.provider.saucelabs.boot').update(time)
        end

        def destroy_vm(vm)
          info "destroying the VM"
          retryable(tries: 3) do
            api.kill_instance(vm['instance_id'])
          end
        end

        def vm_ready?(vm)
          socket = TCPSocket.new(ip_address, 3422)
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
