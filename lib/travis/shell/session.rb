require 'net/ssh'
require 'net/ssh/shell'
require 'patches/net_ssh_shell_process'
require 'fileutils'
require 'shellwords'
require 'vagrant'

module Travis
  module Shell
    class Session

      #
      # API
      #

      # @private
      NEWLINE = "\n"

      # VirtualBox VM instance used by the session
      attr_reader :vm

      # Net::SSH session
      # @return [Net::SSH::Connection::Session]
      attr_reader :shell

      # VBoxManage log file path
      # @return [String]
      attr_reader :log

      def initialize(env)
        @vm    = env.primary_vm.vm
        @shell = start_shell(env)
        @log   = '/tmp/travis/log/vboxmanage'

        yield(self) if block_given?

        FileUtils.mkdir_p(File.dirname(log))
        start_standbox
      end

      def on_output(&block)
        @on_output = block
      end

      def execute(command, options = {})
        command = echoize(command) unless options[:echo] == false
        status = nil

        shell.execute(command) do |process|
          process.on_output do |p, data|
            @on_output.call(p, data) if @on_output
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
        rollback_sandbox
      end

      #
      # Protected
      #

      protected

      def start_shell(env)
        puts "starting ssh session to #{env.config.ssh.host} ..."
        Net::SSH.start(env.config.ssh.host, env.config.ssh.username, :port => 2222, :keys => [env.config.ssh.private_key_path]).shell.tap do
          puts 'done.'
        end
      end

      def echoize(cmd)
        [cmd].flatten.join(NEWLINE).split(NEWLINE).map { |cmd| "echo #{Shellwords.escape("$ #{cmd}")}#{NEWLINE}#{cmd}" }.join(NEWLINE)
      end

      def start_standbox
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
