require 'spec_helper'
require 'travis/worker/factory'

describe Travis::Worker::Factory do
  include_context "march_hare connection"

  let(:config)  { Hashr.new({ :queue => "builds.php" }) }
  let(:factory) { Travis::Worker::Factory.new('worker-name', config, connection) }
  let(:worker)  { factory.worker }

  describe 'worker' do
    after(:each) { worker.shutdown }

    it 'returns a worker' do
      expect(worker).to be_a(Travis::Worker::Instance)
    end

    it 'has a vm' do
      expect(worker.vm.class.to_s).to eq("Travis::Worker::VirtualMachine::Docker")
    end

    describe 'queues' do
      it 'includes individual build queues that were listed in the configuration' do
        expect(worker.queue_name).to eq("builds.php")
      end
    end
  end
end
