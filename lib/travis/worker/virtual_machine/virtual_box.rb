# The Java System property vbox.home needs to be setup to use the vboxjxpcom.jar library.
# This can either be done via the command line using:
#
#   $ruby -J-Dvbox.home=/Applications/VirtualBox.app/Contents/MacOS script_to_run.rb
#
# or by using:
#
#   java.lang.System.setProperty("vbox.home", "/Applications/VirtualBox.app/Contents/MacOS")
#
# Travis takes care of this for you as long as you set the vms.vbox_home config var in the
# worker yml file.
#
# You may need to make /dev/vboxdrv accessible by the current user, either by chmoding the file
# or by adding the user to the group assigned to the file.
#
$: << File.expand_path('../../../../../vendor/virtualbox-4.1.2', __FILE__)
require 'java'

java_import 'java.util.List'
java_import 'java.util.Arrays'
java_import 'java.io.BufferedReader'
java_import 'java.io.InputStreamReader'

module Travis
  module Worker
    module VirtualMachine

      class VmNotFound < StandardError; end

      # A simple encapsulation of the VirtualBox commands used in the
      # Travis Virtual Machine test lifecycle.
      class VirtualBox

        class << self
          # Instantiates and caches the Singleton VirtualBoxManager.
          def manager
            @manager ||= begin
              setup
              VirtualBoxManager.create_instance(nil)
            end
          end

          # Inspects VirtualBox for the number of vms setup for Travis.
          #
          # Returns the number of VMs matching the vm name_prefix in the config.
          def vm_count
            manager.vbox.machines.count do |machine|
              machine.name =~ /#{Travis::Worker.config.vms.name_prefix}/
            end
          end

          # Inspects VirtualBox for the names of the vms setup for Travis.
          #
          # Returns the names of the VMs matching the vm name_prefix in the config.
          def vm_names
            machines = manager.vbox.machines.find_all do |machine|
              machine.name =~ /#{Travis::Worker.config.vms.name_prefix}/
            end
            machines ? machines.map { |machine| machine.name } : []
          end

          # Internal: Defers the setup of the virtual box java library as it requires the Travis config
          def setup
            java.lang.System.setProperty("vbox.home", Travis::Worker.config.vms.vbox_home)

            require 'vboxjxpcom.jar'

            java_import 'org.virtualbox_4_1.VirtualBoxManager'
            java_import 'org.virtualbox_4_1.VBoxEventType'
            java_import 'org.virtualbox_4_1.LockType'
            java_import 'org.virtualbox_4_1.MachineState'
            java_import 'org.virtualbox_4_1.IMachineStateChangedEvent'
          end
        end

        # The name of the virtual box machine.
        attr_reader :name

        # The virtual box machine bound to this instance.
        attr_reader :machine

        # Instantiates a new VirtualBox machine, and connects it to the underlying
        # virtual machine setup in the local virtual box environment based on the box name.
        #
        # name - The Virtual Box vm to connect to.
        #
        # Raises VmNotFound if the virtual machine can not be found based on the name provided.
        def initialize(name)
          @name = name

          @machine = manager.vbox.machines.detect do |machine|
            machine.name == name
          end

          raise VmNotFound, "#{name} VirtualBox VM could not be found" unless machine
        end

        def shell
          @shell ||= Travis::Worker::Shell::Session.new(
            :host => '127.0.0.1',
            :port => ssh_port,
            :username => 'vagrant',
            :private_key_path => File.expand_path("keys/vagrant")
          )
        end

        # Yields a block within a sandboxed virtual box environment
        #
        # block - A required block to be executed during the sandboxing.
        #
        # Returns the result of the block.
        def sandboxed
          start_sandbox
          result = yield
          close_sandbox
          result
        end

        # Sets up the VM with a snapshot for sandboxing if one does not already exist.
        #
        # These operations can take several minutes to complete and it is recommended
        # that you run this method before accepting jobs to work.
        #
        # Returns true.
        def prepare
          if requires_snapshot?
            restart
            wait_for_boot
            # sleep(90)
            pause
            snapshot
            sleep(5) # what do we wait for here? is there a condition we can wait for?
          end
          true
        end

        # Detects the ssh port for the VM
        #
        # Returns the ssh port number if found, otherwise nil
        def ssh_port
          max_adapters = machine.parent.system_properties.get_max_network_adapters(machine.chipset_type)

          max_adapters.times do |i|
            adapter = machine.get_network_adapter(i)

            port_details = adapter.nat_driver.redirects.detect do |redirect|
              redirect.split(',').first == 'ssh'
            end

            if port_details
              return port_details.split(',')[3]
            end
          end

          nil
        end

        protected

          def manager
            self.class.manager
          end

          def start_sandbox
            power_off unless powered_off?
            rollback
            power_on
          end

          def close_sandbox
            power_off
          end

          def requires_snapshot?
            machine.snapshot_count == 0
          end

          def running?
            machine.state == MachineState::Running
          end

          def powered_off?
            machine.state == MachineState::PoweredOff ||
              machine.state == MachineState::Aborted ||
              machine.state == MachineState::Saved
          end

          def power_on
            with_session(false) do |session|
              machine.launch_vm_process(session, 'headless', '')
            end
          end

          def power_off
            with_session do |session|
              session.console.power_down
            end
          end

          def restart
            power_off if running?
            power_on
          end

          def pause
            with_session do |session|
              session.console.pause
            end
          end

          def snapshot
            with_session do |session|
              session.console.take_snapshot('sandbox', "#{machine.get_name} sandbox snapshot taken at #{Time.now}")
            end
          end

          def rollback
            with_session do |session|
              session.console.restore_snapshot(machine.current_snapshot)
            end
          end

          def wait_for_boot
            shell.connect(true)
            shell.close
          end

          def with_session(lock = true)
            session = manager.session_object

            machine.lock_machine(session, LockType::Shared) if lock

            progress = yield(session)
            progress.wait_for_completion(-1) if progress
            sleep(0.5)

            session.unlock_machine if lock
          end
      end
    end
  end
end
