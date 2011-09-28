# start with:
#
# $ ruby -J-Dvbox.home=/Applications/VirtualBox.app/Contents/MacOS vbox.rb
#
# java.lang.System.setProperty("vbox.home", "/Applications/VirtualBox.app/Contents/MacOS")
#
# /dev/vboxdrv needs to be accessible for the current user

require 'java'

java_import 'java.util.List'
java_import 'java.util.Arrays'
java_import 'java.io.BufferedReader'
java_import 'java.io.InputStreamReader'

module Travis
  module Worker
    module VirtualMachine

      class VirtualBox
        attr_reader :name, :manager, :machine

        def initialize(name)
          setup

          @name = name
          @manager = VirtualBoxManager.create_instance(nil)
          @machine = manager.vbox.machines.get(0)
        end

        def setup
          java.lang.System.setProperty("vbox.home", Travis::Worker.config.vms.vbox_home)

          require 'vboxjxpcom.jar'

          java_import 'org.virtualbox_4_0.VirtualBoxManager'
          java_import 'org.virtualbox_4_0.VBoxEventType'
          java_import 'org.virtualbox_4_0.LockType'
          java_import 'org.virtualbox_4_0.MachineState'
          java_import 'org.virtualbox_4_0.IMachineStateChangedEvent'
        end

        def sandboxed
          start_sandbox
          yield
          close_sandbox
        end

        protected

          def start_sandbox
            power_off if running?
            snapshot  if snapshot?
            power_on
          end

          def close_sandbox
            power_off
            rollback
          end

          def state
            machine.state
          end

          def running?
            machine.state == MachineState::Running
          end

          def snapshot?
            machine.snapshot_count == 0
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
              session.console.take_snapshot('sandbox', "#{machine.name} sandbox snapshot taken at #{Time.now}")
            end
          end

          def rollback
            with_machine_session do |session|
              session.console.restore_snapshot(machine.current_snapshot)
            end
          end

          def with_session
            session = manager.get_session_object

            progress = yield(session)
            progress.wait_for_completion(-1)
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

    end
  end
end