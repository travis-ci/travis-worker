require 'net/ssh'
require 'net/ssh/shell'
require 'patches/net_ssh_shell_process'
require 'fileutils'
require 'vagrant'

module Travis
  module Shell
    class Session
      autoload :Helpers, 'travis/shell/helpers'

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
      end

      def sandboxed
        start_sandbox
        yield
        rollback_sandbox
      end

      def execute(command, options = {})
        command = echoize(command) unless options[:echo] == false
        status = nil

        shell.execute(command) do |process|
          process.on_output do |p, data|
            buffer << data
          end
          process.on_finish do |p|
            status = p.exit_status
          end
        end
        shell.session.loop { status.nil? }

        status == 0
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

        def start_shell
          puts "starting ssh session to #{config.host} ..."
          Net::SSH.start(config.host, config.username, :port => 2222, :keys => [config.private_key_path]).shell.tap do
            puts 'done.'
          end
        end

        def buffer
          @buffer ||= Buffer.new do |string|
            @on_output.call(string) if @on_output
          end
        end

        def start_sandbox
          puts 'creating vbox snapshot ...'
          vbox_manage "snapshot '#{vm.name}' take 'travis-sandbox'"
          puts 'done.'
        end

        def rollback_sandbox
          puts 'rolling back to vbox snapshot ...'
          vbox_manage "controlvm '#{vm.name}' poweroff"
          vbox_manage "snapshot '#{vm.name}' restore 'travis-sandbox'"
          vbox_manage "snapshot '#{vm.name}' delete 'travis-sandbox'"
          vbox_manage "startvm --type headless '#{vm.name}'"
          puts 'done.'
        end

        def vbox_manage(cmd)
          system "VBoxManage #{cmd}", :out => log, :err => log
        end
    end # Session
  end # Shell
end # Travis
