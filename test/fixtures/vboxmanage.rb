FIXTURES.merge! :vboxmanage => <<-txt
Name:            travis-worker_1308835149
Guest OS:        Ubuntu
UUID:            970e58e2-2ae5-4fc5-8760-5f988096f6a9
Config file:     /Volumes/Users/sven/VirtualBox VMs/travis-worker_1308835149/travis-worker_1308835149.vbox
Snapshot folder: /Volumes/Users/sven/VirtualBox VMs/travis-worker_1308835149/Snapshots
Log folder:      /Volumes/Users/sven/VirtualBox VMs/travis-worker_1308835149/Logs
Hardware UUID:   970e58e2-2ae5-4fc5-8760-5f988096f6a9
Memory size:     1536MB
Page Fusion:     off
VRAM size:       8MB
HPET:            off
Chipset:         piix3
Firmware:        BIOS
Number of CPUs:  1
Synthetic Cpu:   off
CPUID overrides: None
Boot menu mode:  message and menu
Boot Device (1): HardDisk
Boot Device (2): DVD
Boot Device (3): Not Assigned
Boot Device (4): Not Assigned
ACPI:            on
IOAPIC:          off
PAE:             off
Time offset:     0 ms
RTC:             local time
Hardw. virt.ext: on
Hardw. virt.ext exclusive: off
Nested Paging:   on
Large Pages:     off
VT-x VPID:       on
State:           running (since 2011-06-27T15:36:37.182000000)
Monitor count:   1
3D Acceleration: off
2D Video Acceleration: off
Teleporter Enabled: off
Teleporter Port: 0
Teleporter Address:
Teleporter Password:
Storage Controller Name (0):            IDE Controller
Storage Controller Type (0):            PIIX4
Storage Controller Instance Number (0): 0
Storage Controller Max Port Count (0):  2
Storage Controller Port Count (0):      2
Storage Controller Bootable (0):        on
Storage Controller Name (1):            SATA Controller
Storage Controller Type (1):            IntelAhci
Storage Controller Instance Number (1): 0
Storage Controller Max Port Count (1):  30
Storage Controller Port Count (1):      30
Storage Controller Bootable (1):        on
IDE Controller (1, 0): Empty
SATA Controller (0, 0): /Volumes/Users/sven/VirtualBox VMs/travis-worker_1308835149/box-disk1.vmdk (UUID: 2caaafb1-5af3-4e64-98fa-ee29d6321d88)
NIC 1:           MAC: 080027EF2AA7, Attachment: NAT, Cable connected: on, Trace: off (file: none), Type: 82540EM, Reported speed: 0 Mbps, Boot priority: 0
NIC 1 Settings:  MTU: 0, Socket( send: 64, receive: 64), TCP Window( send:64, receive: 64)
NIC 1 Rule(0):   name = ssh, protocol = tcp, host ip = , host port = 2222, guest ip = , guest port = 22
NIC 2:           disabled
NIC 3:           disabled
NIC 4:           disabled
NIC 5:           disabled
NIC 6:           disabled
NIC 7:           disabled
NIC 8:           disabled
Pointing Device: PS/2 Mouse
Keyboard Device: PS/2 Keyboard
UART 1:          disabled
UART 2:          disabled
Audio:           disabled
Clipboard Mode:  Bidirectional
VRDE:            disabled
USB:             disabled

USB Device Filters:

<none>

Shared folders:

Name: 'v-root', Host path: '/Volumes/Users/sven/Development/projects/travis/travis-worker' (machine mapping), writable
Name: 'v-csc-0', Host path: '/Volumes/Users/sven/Development/projects/travis/travis-worker/vendor/cookbooks/vagrant_base' (machine mapping), writable

Guest:

Configured memory balloon size:      0 MB

Snapshots:

   Name: travis-worker_1309125270-sandbox (UUID: fc54e7fe-7af2-496d-925a-9b29fa5d0234)
      Name: travis-worker_1309125270-sandbox (UUID: f15bc668-c09c-46c0-82b4-b621226c8bd3)
      Name: travis-worker_1309125270-sandbox (UUID: 6c08e3b2-1c9c-4d9a-99eb-5abd2b2d0bdc)
      Name: travis-worker_1309125270-sandbox (UUID: 1fbd6ddb-733b-4711-a1b3-05206f4396f0)
      Name: travis-worker_1309188712-sandbox (UUID: df764451-0b17-4492-974a-9f20077fc70d) *
         Name: travis-worker_1309188712-sandbox (UUID: edbd462c-9fb9-40c7-aef9-8bf4978adf60)

txt
