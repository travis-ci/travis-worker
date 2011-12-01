require 'spec_helper'

describe Travis::Worker::Factory do
  let(:factory) { Travis::Worker::Factory.new('worker-name') }
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
      it 'includes a consumer with the reporting key "builds.configure"' do
        worker.queues.first.name.should == 'builds.configure'
      end

      it 'includes a consumer with the reporting key "builds.common"' do
        worker.queues.last.name.should == 'builds.common'
      end
    end

    describe 'reporter' do
      it 'is a Reporter' do
        worker.reporter.should be_a(Travis::Worker::Reporter)
      end

      it 'has a jobs exchange exchange' do
        worker.reporter.jobs.should be_a(Travis::Amqp::Publisher)
      end

      it 'the jobs exchange has the reporting key "reporting.jobs"' do
        worker.reporter.jobs.routing_key.should == 'reporting.jobs'
      end

      it 'has a jobs exchange exchange' do
        worker.reporter.workers.should be_a(Travis::Amqp::Publisher)
      end

      it 'the workers exchange has the reporting key "reporting.jobs"' do
        worker.reporter.workers.routing_key.should == 'reporting.workers'
      end
    end
  end
end
