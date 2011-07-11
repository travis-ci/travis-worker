require 'net/ssh'
require 'net/ssh/shell'
require 'travis/worker/patches/net_ssh_shell_process'
require 'fileutils'
require 'vagrant'

module Travis
  module Worker
    module Shell
      class Session
        autoload :Helpers, 'travis/worker/shell/helpers'

        include Shell::Helpers
        #
        # API
        #

        # VirtualBox VM instance used by the session
        attr_reader :vm

        # VirtualBox environment ssh configuration
        attr_reader :config

        # Net::SSH session
        # @return [Net::SSH::Connection::Session]
        attr_reader :shell

        # VBoxManage log file path
        # @return [String]
        attr_reader :log

        def initialize(vm, config)
          @vm     = vm
          @config = config
          @shell  = start_shell
          @log    = "log/vboxmanage.#{vm.name}.log"

          yield(self) if block_given?

          FileUtils.mkdir_p(File.dirname(log))
          FileUtils.touch(log)
        end

        def sandboxed
          begin
            start_sandbox
            yield
          ensure
            rollback_sandbox
          end
        end

        def execute(command, options = {})
          timeout = options[:timeout].is_a?(Numeric) ? options[:timeout] : Travis::Worker.config.timeouts[options[:timeout]]
          command = timetrap(command, :timeout => timeout) if options[:timeout]
          command = echoize(command) unless options[:echo] == false
          exec(command) { |p, data| buffer << data } == 0
        end

        def evaluate(command)
          result = ''
          status = exec(command) { |p, data| result << data }
          raise("command #{command} failed: #{result}") unless status == 0
          result
        end

        def close
          shell.wait!
          shell.close!
          buffer.flush
        end

        def on_output(&block)
          @on_output = block
        end

        #
        # Protected
        #

        protected

        def vm_name
          vm.vm.name
        end

        def start_shell
          puts "starting ssh session to #{config.host}:#{vm.ssh.port} ..."
          Net::SSH.start(config.host, config.username, :port => vm.ssh.port, :keys => [config.private_key_path]).shell.tap do
            puts 'done.'
          end
        end

        def buffer
          @buffer ||= Buffer.new do |string|
            @on_output.call(string) if @on_output
          end
        end

        def exec(command, &on_output)
          status = nil
          shell.execute(command) do |process|
            process.on_output(&on_output)
            process.on_error_output(&on_output)
            process.on_finish { |p| status = p.exit_status }
          end
          shell.session.loop { status.nil? }
          status
        end

        def start_sandbox
          vbox_take_snapshot
        end

        def rollback_sandbox
          vbox_power_off
          vbox_delete_snapshots
          vbox_start_vm
        rescue
          puts "#{$!.class.name}: #{$!.message}", $@
        end

        def vbox_take_snapshot
          puts "[vbox] Taking snapshot on #{vm_name}"
          vbox_manage "snapshot '#{vm_name}' take '#{vm_name}-sandbox'", :wait => "showvminfo '#{vm_name}' | grep #{vm_name}-sandbox"
          puts "[vbox] Taken."
        end

        def vbox_power_off
          puts "[vbox] Powering off #{vm_name} ..."
          vbox_manage "controlvm '#{vm_name}' poweroff", :wait => "showvminfo '#{vm_name}' | grep State | grep 'powered off'"
          puts "[vbox] Powered off."
        end

        def vbox_restore_snapshot
          puts "[vbox] Restoring current snapshot ..."
          vbox_manage "snapshot '#{vm_name}' restorecurrent"
          puts "[vbox] Restored."
        end

        def vbox_delete_snapshots
          vbox_snapshots.reverse.each do |snapshot|
            vbox_restore_snapshot
            puts "[vbox] Deleting snapshot #{snapshot} ..."
            vbox_manage "snapshot '#{vm_name}' delete '#{snapshot}'"
            puts "[vbox] Deleted."
          end
        end

        def vbox_start_vm
          puts "[vbox] Starting #{vm_name} ..."
          vbox_manage "startvm --type headless '#{vm_name}'", :wait => "showvminfo '#{vm_name}' | grep State | grep 'running'"
          puts "[vbox] Started."
        end

        def vbox_manage(cmd, options = {})
          cmd = "VBoxManage #{cmd} >> #{log} 2>&1"
          puts "[vbox] #{cmd}" unless options[:eval]
          system(cmd).tap do |result|
            raise "[vbox] #{cmd} failed. See #{log} for more information." unless result || options[:eval]
            vbox_wait(options[:wait]) if options[:wait]
          end
        end

        def vbox_eval(cmd)
          system "VBoxManage #{cmd} > /dev/null 2>&1"
        end

        def vbox_wait(cmd)
          sleep(0.5) until vbox_eval(cmd)
        end

        def vbox_snapshots
          info = `vboxmanage showvminfo #{vm_name} --details`
          if info =~ /^Snapshots\s*/
            info.split(/^Snapshots\s*/).last.split("\n").map { |line| line =~ /\(UUID: ([^\)]*)\)/ and $1 }.compact
          else
            []
          end
        end
      end # Session
    end # Shell
  end # Worker
end # Travis
