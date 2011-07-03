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
          @log    = '/tmp/travis/log/vboxmanage'

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
          puts '[vbox] Creating vbox snapshot ...'
          vbox_manage "snapshot '#{vm_name}' take '#{vm_name}-sandbox'"
          puts '[vbox] Created.'
        end

        def rollback_sandbox
          puts '[vbox] Rolling back to vbox snapshot ...'
          vbox_manage "controlvm '#{vm_name}' poweroff"
          vbox_manage "snapshot '#{vm_name}' restorecurrent"
          delete_snapshots
          vbox_manage "startvm --type headless '#{vm_name}'"
          puts '[vbox] Rolled back.'
        rescue
          puts "#{$!.class.name}: #{$!.message}", $@
        end

        def delete_snapshots
          snapshots.reverse.each do |snapshot|
            puts "[vbox] Deleting snapshot #{snapshot}..."
            vbox_manage "snapshot '#{vm_name}' delete '#{snapshot}'"
            puts "[vbox] Deleted."
          end
        end

        def vbox_manage(cmd)
          cmd = "VBoxManage #{cmd} 2>&1 > #{log}"
          puts "[vbox] #{cmd}"
          result = system(cmd)
          raise "[vbox] #{cmd} failed. See #{log} for more information." unless result
        end

        def snapshots
          info = `vboxmanage showvminfo #{vm_name} --details`
          info.split(/^Snapshots\s*/).last.split("\n").map { |line| line =~ /\(UUID: ([^\)]*)\)/ and $1 }.compact
        end
      end # Session
    end # Shell
  end # Worker
end # Travis
