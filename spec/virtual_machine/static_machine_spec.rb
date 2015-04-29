require 'travis/worker/virtual_machine/static_machine'
require 'travis/worker/ssh/session'
require 'travis/worker'
require 'pp'
require 'hashr'

module Travis::Worker::VirtualMachine
  describe StaticMachine do
    before do
      Travis::Worker.config.static_machine = Struct.new(nil, :ip, :port, :username, :private_key_path).new(['192.168.0.1', '192.168.0.2'], 22, 'travis')
      Travis::Worker.config.vms.count = 2
    end

    let(:static_machine1) {described_class.new('foo-1')}
    let(:static_machine2) {described_class.new('foo-2')}

    it 'assigns righe IP according to worker number' do

      static_machine1.sandboxed({}) do
        static_machine1.session
        expect(static_machine1.send(:ip_address)).to eq('192.168.0.1')
      end
      static_machine2.sandboxed({}) do
        static_machine2.session
        expect(static_machine2.send(:ip_address)).to eq('192.168.0.2')
      end
    end
  end
end
