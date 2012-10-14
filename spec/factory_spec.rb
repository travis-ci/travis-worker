require 'spec_helper'

describe Travis::Worker::Factory do
  include_context "hot_bunnies connection"

  let(:config)  { Hashr.new({ :queue => "builds.php" }) }
  let(:factory) { Travis::Worker::Factory.new('worker-name', config, connection) }
  let(:worker)  { factory.worker }

  describe 'worker' do
    after(:each) { worker.shutdown }

    it 'returns a worker' do
      worker.should be_a(Travis::Worker::Instance)
    end

    it 'has a vm' do
      worker.vm.class.to_s.should == "Travis::Worker::VirtualMachine::VirtualBox"
    end

    describe 'queues' do
      it 'includes individual build queues that were listed in the configuration' do
        worker.queue_name.should == "builds.php"
      end
    end
  end
end
