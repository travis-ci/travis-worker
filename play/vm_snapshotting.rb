# start with:
#
# $ ruby -J-Dvbox.home=/Applications/VirtualBox.app/Contents/MacOS vbox.rb
#
# /dev/vboxdrv needs to be accessible for the current user

require 'rubygems'
require 'thread'
require 'java'
require 'vboxjxpcom.jar'

java_import 'org.virtualbox_4_1.VirtualBoxManager'
java_import 'org.virtualbox_4_1.VBoxEventType'
java_import 'org.virtualbox_4_1.LockType'
java_import 'org.virtualbox_4_1.MachineState'
java_import 'org.virtualbox_4_1.IMachineStateChangedEvent'

class VBox
  attr_reader :manager, :machine

  def initialize
    @manager = VirtualBoxManager.create_instance(nil)
    @machine = manager.get_vbox.get_machines.get(0)
  end

  def sandboxed
    start_sandbox
    yield
    close_sandbox
  end

  def state
    machine.state
  end

  protected

    def start_sandbox
      power_off if running?
      rollback
      snapshot
      power_on unless running?
    end

    def close_sandbox
      # nothing to do here
    end

    def running?
      machine.state == MachineState::Running
    end

    def power_on
      with_session do |session|
        machine.launch_vm_process(session, 'headless', '')
      end
    end

    def power_off
      with_session do |session|
        machine.lock_machine(session, LockType::Shared)
        session.console.power_down
      end
    end

    def snapshot
      with_machine_session do |session|
        session.console.take_snapshot('sandbox', "#{machine.get_name} sandbox snapshot taken at #{Time.now}")
      end
    end

    def rollback
      with_machine_session do |session|
        session.console.delete_snapshot(machine.current_snapshot.id)
      end while machine.current_snapshot
    end

    def with_session
      session = manager.get_session_object

      progress = yield(session)
      progress.wait_for_completion(-1)
      sleep(0.5)
    rescue

    ensure
      session.unlock_machine
    end

    def with_machine_session
      session = manager.open_machine_session(machine)

      progress = yield(session)
      progress.wait_for_completion(-1)
      sleep(0.5)
    ensure
      manager.close_machine_session(session)
    end
end

require 'rubygems'
require 'net/ssh/shell'


def execute(shell, cmd)
  status = nil
  shell.execute(cmd) do |process|
    process.on_output { |p, output| puts output }
    process.on_finish { |p| status = p.exit_status }
  end
  shell.session.loop { status.nil? }
end


vbox = VBox.new
3.times do
  puts vbox.state
  puts "starting sandbox"
  vbox.sandboxed do
    puts 'do work ...'
    shell = Net::SSH.start('127.0.0.1', 'vagrant', :port => 2221, :keys => ['/Users/joshkalderimis/.rvm/gems/jruby-1.6.4@travis-worker/gems/vagrant-0.8.7/keys/vagrant']).shell
    execute(shell, 'ls; echo "BAR" > bar; ls')
  end
  puts "rolled back"
end
