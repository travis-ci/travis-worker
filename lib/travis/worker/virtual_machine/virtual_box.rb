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
$: << File.expand_path('../../../../../vendor/virtualbox-4.1.18', __FILE__)

require 'java'
require 'travis/support'

java_import 'java.util.List'
java_import 'java.util.Arrays'
java_import 'java.io.BufferedReader'
java_import 'java.io.InputStreamReader'

module Travis
  class Worker
    module VirtualMachine
      class VmNotFound < StandardError; end

      # A simple encapsulation of the VirtualBox commands used in the
      # Travis Virtual Machine lifecycle.
      class VirtualBox
        include Retryable, Logging

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
            java_import 'org.virtualbox_4_1.DeviceType'
            java_import 'org.virtualbox_4_1.AccessMode'
            java_import 'org.virtualbox_4_1.MediumType'
            java_import 'org.virtualbox_4_1.SessionState'
          end
        end

        attr_reader :name

        # Instantiates a new VirtualBox machine, and connects it to the underlying
        # virtual machine setup in the local virtual box environment based on the box name.
        #
        # name - The Virtual Box vm to connect to.
        #
        # Raises VmNotFound if the virtual machine can not be found based on the name provided.
        def initialize(name)
          @name = name
        end

        # The virtual box machine bound to this instance.
        def machine
          @machine = begin
            machine = manager.vbox.machines.detect { |machine| machine.name == name }
            raise VmNotFound, "#{name} VirtualBox VM could not be found" unless machine
            machine
          end
        end

        # Prepares a ssh session bound to the virtual box vm.
        #
        # Returns a Shell::Session.
        def shell
          @shell ||= Shell::Session.new(name,
            :host => '127.0.0.1',
            :port => ssh_port,
            :username => 'vagrant',
            :private_key_path => File.expand_path('keys/vagrant'),
            :buffer => Travis::Worker.config.shell.buffer,
            :timeouts => Travis::Worker.config.timeouts
          )
        end

        # Yields a block within a sandboxed virtual box environment
        #
        # block - A required block to be executed during the sandboxing.
        #
        # Returns the result of the block.
        def sandboxed
          start_sandbox
          yield
        rescue Exception => e
          log_exception(e)
        ensure
          close_sandbox
        end

        # Sets up the VM with a snapshot for sandboxing if one does not already exist.
        #
        # These operations can take several minutes to complete and it is recommended
        # that you run this method before accepting jobs to work.
        #
        # Returns true.
        def prepare
          if requires_snapshot?
            info "Preparing vm #{name} ..."
            restart { immutate }
            wait_for_boot
            pause
            snapshot
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

        def full_name
          "#{Travis::Worker.config.host}:#{name}"
        end

        def logging_header
          name
        end

        def vm_pid
          ps_lines = `ps aux | grep #{name}`.split("\n")
          if ps_lines.size == 3
            ps_lines.first.split[1]
          else
            nil
          end
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
            power_off unless powered_off?
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
            info "#{name} started with process id : #{vm_pid}"
          end

          def power_off
            with_session do |session|
              session.console.power_down
            end
          end

          def restart
            power_off if running?
            yield if block_given?
            power_on
          end

          def pause
            with_session do |session|
              session.console.pause
            end
          end

          def snapshot
            with_session do |session|
              session.console.take_snapshot('sandbox', "#{machine.get_name} sandbox snapshot taken at #{Time.now.utc}")
            end
            sleep(3) # this makes sure the snapshot is finished and ready
          end

          def rollback
            with_session do |session|
              session.console.restore_snapshot(machine.current_snapshot)
            end
          end

          def immutate
            return if immutable?

            attachment = machine.medium_attachments.detect { |ma| ma.controller =~ /SATA/ }

            controller_name = attachment.controller
            medium_path     = attachment.medium.location.to_s

            detach_device(controller_name)

            medium = manager.vbox.open_medium(medium_path, DeviceType::HardDisk, AccessMode::ReadWrite, false)
            medium.type = MediumType::Immutable

            attach_device(controller_name, medium)
          end

          def immutable?
            machine.medium_attachments.detect { |ma| ma.controller =~ /SATA/ }.medium.type == MediumType::Immutable
          end

          def detach_device(controller_name)
            with_session do |session|
              session.machine.detach_device(controller_name, 0, 0)
              session.machine.save_settings
            end
          end

          def attach_device(controller_name, medium)
            with_session do |session|
              session.machine.attach_device(controller_name, 0, 0, DeviceType::HardDisk, medium)
              session.machine.save_settings
            end
          end

          def wait_for_boot
            retryable(:tries => 3) do
              shell.connect(false)
              shell.close
            end
            sleep(10) # make sure the vm has some time to start other services
          end

          def with_session(lock = true)
            session = manager.session_object

            lock_machine(session) if lock

            progress = yield(session)
            progress.wait_for_completion(-1) if progress
            sleep(0.5)
          ensure
            unlock_machine(session)
          end

          def lock_machine(session)
            unlock_machine(session)
            machine.lock_machine(session, LockType::Shared)
          end

          def unlock_machine(session)
            if session
              debug "#{name} session in #{session.state} state"
              session.unlock_machine if session.state == SessionState::Locked
            end
          end
      end
    end
  end
end
