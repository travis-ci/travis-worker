# start with:
#
# $ ruby -J-Dvbox.home=/Applications/VirtualBox.app/Contents/MacOS vbox.rb
#
# /dev/vboxdrv needs to be accessible for the current user
#
# java.lang.System.setProperty("vbox.home", "/Applications/VirtualBox.app/Contents/MacOS")
#

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

  def setup_sandbox
    puts 'setting up sandbox'
    if requires_snapshot?
      puts 'snapshot required!'
      restart
      sleep(90)
      snapshot
      sleep(5)
      puts 'you now have a snapshot'
    else
      puts 'snapshot already exists'
    end
  end

  protected

    def start_sandbox
      puts 'starting sandbox'
      power_off unless powered_off?
      rollback
      power_on
    end

    def close_sandbox
      puts 'closing sandbox'
      power_off
    end

    def requires_snapshot?
      machine.snapshot_count == 0
    end

    def running?
      puts "vm is #{machine.state.to_s}"
      machine.state == MachineState::Running
    end

    def powered_off?
      puts "vm is #{machine.state.to_s}"
      machine.state == MachineState::PoweredOff || machine.state == MachineState::Aborted
    end

    def power_on
      with_session do |session|
        puts 'powering on'
        machine.launch_vm_process(session, 'headless', '')
      end
    end

    def power_off
      with_session do |session|
        puts 'powering off'
        machine.lock_machine(session, LockType::Shared)
        session.console.power_down
      end
    end

    def restart
      power_off if running?
      power_on
    end

    def pause
      with_session do |session|
        puts 'powering on'
        machine.lock_machine(session, LockType::Shared)
        session.console.pause
      end
    end

    def snapshot
      pause if running?
      with_session do |session|
        puts 'snapshotting'
        machine.lock_machine(session, LockType::Shared)
        session.console.take_snapshot('sandbox', "#{machine.get_name} sandbox snapshot taken at #{Time.now}")
      end
    end

    def rollback
      with_session do |session|
        puts 'rolling back'
        machine.lock_machine(session, LockType::Shared)
        session.console.restore_snapshot(machine.current_snapshot)
      end
    end

    def with_session
      session = manager.session_object

      progress = yield(session)
      progress.wait_for_completion(-1) if progress
      sleep(0.5)

      session.unlock_machine
    end

    def with_machine_session
      session = manager.open_machine_session(machine)

      progress = yield(session)
      progress.wait_for_completion(-1)
      sleep(0.5)

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


puts '-------------------------------'
puts "starting sandbox test"
puts "-------------------------------\n\n"
vbox = VBox.new

vbox.setup_sandbox

5.times do |n|
  puts "Starting run #{n}"
  puts "vbox state : #{vbox.state}"
  vbox.sandboxed do
    ssh = Net::SSH.start('127.0.0.1', 'vagrant', :port => 2221, :keys => ['/Users/joshkalderimis/.rvm/gems/ruby-1.9.2-p290/gems/vagrant-0.8.7/keys/vagrant'])
    shell = ssh.shell
    execute(shell, 'ls; echo "BAR" > bar')
    ssh.close
  end
  puts "vbox state : #{vbox.state}"
  puts "all done\n\n"
end
