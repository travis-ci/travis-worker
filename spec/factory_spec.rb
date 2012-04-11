require 'spec_helper'

describe Travis::Worker::Factory do
  include_context "hot_bunnies connection"

  let(:config)  { Hashr.new({ :queues => %w(builds.php builds.python builds.perl) }) }
  let(:factory) { Travis::Worker::Factory.new('worker-name', config, connection) }
  let(:worker)  { factory.worker }

  describe 'worker' do
    after(:each) { worker.shutdown }

    it 'returns a worker' do
      worker.should be_a(Travis::Worker)
    end

    it 'has a vm' do
      worker.vm.should be_a(Travis::Worker::VirtualMachine::VirtualBox)
    end

    describe 'queues' do
      it 'includes individual build queues that were listed in the configuration' do
        worker.queue_names.should include("builds.php")
        worker.queue_names.should include("builds.python")
        worker.queue_names.should include("builds.perl")
      end
    end
  end
end
