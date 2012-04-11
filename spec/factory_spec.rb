require 'spec_helper'

describe Travis::Worker::Factory do
  let(:connection)   { HotBunnies.connect(:hostname => "127.0.0.1") }
  let(:config) { Hashr.new({ :queues => %w(builds.php builds.python builds.perl) }) }
  let(:factory) do
    Travis::Worker::Factory.new('worker-name', config, connection)
  end
  let(:worker)  { factory.worker }

  describe 'worker' do
    after :each do
      worker.shutdown
      connection.close if connection.open?
    end

    it 'returns a worker' do
      worker.should be_a(Travis::Worker)
    end

    it 'has a vm' do
      worker.vm.should be_a(Travis::Worker::VirtualMachine::VirtualBox)
    end

    describe 'queues' do
      after :each do
        worker.shutdown
        connection.close
      end

      it 'includes individual build queues that were listed in the configuration' do
        worker.queue_names.should include("builds.php")
        worker.queue_names.should include("builds.python")
        worker.queue_names.should include("builds.perl")
      end
    end
  end
end
