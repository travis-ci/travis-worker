#!/usr/bin/env ruby
require 'rubygems'
require 'net/ssh'
require 'net/ssh/shell'
require 'vagrant'
require 'sahara'
require 'fileutils'

require 'travis/shell'

# Net::SSH::Shell::Process.class_eval do
#   def on_stdout(ch, data)
#     # if data.strip =~ /^#{manager.separator} (\\d+)$/
#     if data.strip =~ /#{manager.separator} (\\d+)$/
#       before = $`
#       output!(before) unless before.empty?
#       finished!($1)
#     else
#       output!(data)
#     end
#   end
# end
#
# module Travis
#   class SSH
#     attr_reader :vm, :shell, :log, :on_output, :on_finish
#
#     def initialize(env)
#       @vm    = env.primary_vm.vm || raise('vagrant vm must be up')
#       @shell = Net::SSH.start(env.config.ssh.host, env.config.ssh.username, :port => 2222, :keys => [env.config.ssh.private_key_path]).shell
#       @log   = '/tmp/travis/log/vboxmanage'
#
#       FileUtils.mkdir_p(File.dirname(log))
#       sandbox_start
#     end
#
#     def execute(command)
#       status = nil
#       shell.execute(command) do |process|
#         process.on_output do |p, data|
#           on_output.call(p, data) if on_output
#         end
#         process.on_finish do |p|
#           on_finish.call(p) if on_finish
#           status = p.exit_status
#         end
#       end
#       shell.session.loop { status.nil? }
#       status
#     end
#
#     def on_output(&block)
#       @on_output = block
#     end
#
#     def on_finish(&block)
#       @on_finish = block
#     end
#
#     def close
#       shell.wait!
#       shell.close!
#       sandbox_rollback
#     end
#
#     protected
#
#       def sandbox_start
#         vbox_manage "snapshot '#{vm.name}' take 'travis-sandbox'"
#       end
#
#       def sandbox_rollback
#         vbox_manage "controlvm '#{vm.name}' poweroff"
#         vbox_manage "snapshot '#{vm.name}' restore 'travis-sandbox'"
#         vbox_manage "startvm --type headless '#{vm.name}'"
#       end
#
#       def vbox_manage(cmd)
#         system "VBoxManage #{cmd}", :out => log, :err => log
#       end
#   end
# end


commands = [
  'echo "FOO"'
  # 'source ~/.rvm/scripts/rvm',
  # 'cd /tmp/travis/builds/test-project-1',
  # 'rake'
]

env = Vagrant::Environment.new.load!
ssh = Travis::Shell::Session.new(env)
commands.each do |command|
  puts "\n$ #{command}"
  status = ssh.execute(command)
  puts "exit status: #{status.inspect}"
end
ssh.close
