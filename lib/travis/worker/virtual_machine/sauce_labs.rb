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
          setup_wrapper_script
          yield
        ensure
          session.close if @session
          destroy_server
        end

        def full_name
          "#{Travis::Worker.config.host}:travis-#{name}"
        end

        private

        def setup_wrapper_script
          # Return if we're running on a VM with this already added to it
          return if @vm_image =~ /osx9.1/

          # TODO: All of this should be added to the VM itself so we don't have
          # to boot the VM twice.

          info "Uploading wrapper script"
          session.upload_file("~/runner.rb", <<EOF)
#!/usr/bin/env ruby

require "pty"
require "socket"

server = TCPServer.new("127.0.0.1", 15782)
socket = server.accept

PTY.open do |io, file|
  pid = Process.spawn({"TERM" => "xterm"}, "/bin/bash", "--login", "/Users/travis/build.sh", [:out, :err] => file)
  pipe_thread = Thread.new do
    loop do
      socket.print(io.read(1))
    end
  end

  _, exit_status = Process.wait2(pid)
  pipe_thread.kill

  File.open("/Users/travis/build.sh.exit", "w") { |f| f.print((exit_status.exitstatus || 127).to_s) }
end

socket.close
EOF

          session.exec("chmod +x ~/runner.rb")

          info "Uploading launch agent"
          session.upload_file("~/Library/LaunchAgents/com.travis-ci.job-runner.plist", <<EOF)
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
  <dict>
    <key>Label</key>
    <string>com.travis-ci.job-runner</string>
    <key>Program</key>
    <string>/Users/travis/runner.rb</string>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>StandardOutPath</key>
    <string>/tmp/job_runner.log</string>
    <key>StandardErrorPath</key>
    <string>/tmp/job_runner_err.log</string>
  </dict>
</plist>
EOF

          info "Enabling launch agent"
          session.exec("launchctl load ~/Library/LaunchAgents/com.travis-ci.job-runner.plist")
          info "Rebooting VM"
          session.exec("sudo reboot")
          session.close
          @session = nil
          # Wait for the shutdown process to start and the SSHd to shut down
          sleep 10
          Fog.wait_for(240, 3) do
            vm_ready?(@server)
          end
          info "Done rebooting, proceeding with build"
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
          info "Booting #{hostname} (#{ip_address}), #{@server["instance_id"]}"
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

          info "Booting image #{image_name} (#{@vm_image})"

          instance_id = api.start_instance({ hostname: hostname, source: "worker", worker_pid: Process.pid }, @vm_image)['instance_id']
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

          time = Benchmark.realtime do
            retryable(tries: 3) do
              api.kill_instance(vm['instance_id'])
            end

            Fog.wait_for(60, 2) do
              vm_destroyed?(vm)
            end
          end

          info "destroyed VM in #{time.round(2)} seconds"
          Metriks.timer("worker.vm.provider.saucelabs.shutdown").update(time)
        end

        def vm_ready?(vm)
          socket = TCPSocket.new(ip_address, 3422)
          true
        rescue StandardError
          false
        ensure
          socket.close if socket
        end

        def vm_destroyed?(vm)
          api.instance_info(vm['instance_id'])['State'] != 'poweredOn'
        rescue
          # The instance info could potentially disappear by the time we
          # query it, in which case the instance is shut down.
          false
        end
      end
    end
  end
end
