require 'spec_helper'

describe Travis::Worker::Factory do
  let(:config) { Hashr.new({ :queues => %w(builds.php builds.python builds.perl) }) }
  let(:factory) do
    Travis::Worker::Factory.new('worker-name', config)
  end
  let(:worker)  { factory.worker }

  before(:each) { Travis::Amqp.stubs(:connection).returns(stub('amqp')) }

  describe 'worker' do
    it 'returns a worker' do
      worker.should be_a(Travis::Worker)
    end

    it 'has a vm' do
      worker.vm.should be_a(Travis::Worker::VirtualMachine::VirtualBox)
    end

    describe 'queues' do
      it 'includes builds.configure' do
        worker.queue_names.first.should == 'builds.configure'
      end

      it 'includes individual build queues that were listed in the configuration' do
        worker.queue_names.should include("builds.php")
        worker.queue_names.should include("builds.python")
        worker.queue_names.should include("builds.perl")
      end
    end
  end
end
