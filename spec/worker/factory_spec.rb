require 'spec_helper'

describe Worker::Factory do
  let(:factory) { Worker::Factory.new('worker-name') }
  let(:worker)  { factory.worker }

  before(:each) { Messaging.stubs(:connection).returns(stub('amqp')) }

  describe 'worker' do
    it 'returns a worker' do
      worker.should be_a(Worker::Worker)
    end

    it 'has a vm' do
      worker.vm.should be_a(VirtualMachine::VirtualBox)
    end

    describe 'queue' do
      it 'is a messaging hub' do
        worker.queue.should be_a(Messaging::Hub)
      end

      it 'has the reporting key "builds"' do
        worker.queue.name.should == 'builds' # TODO should come from Travis::Worker.config, no?
      end
    end

    describe 'reporter' do
      it 'is a Reporter' do
        worker.reporter.should be_a(Reporter)
      end

      it 'has a reporting hub' do
        worker.reporter.exchange.should be_a(Messaging::Hub)
      end

      it 'has the reporting key "reporting.jobs"' do
        worker.reporter.exchange.name.should == 'reporting.jobs'
      end
    end
  end
end
