require 'spec_helper'
require 'stringio'

describe Manager do
  let(:logger)    { Util::Logging::Logger.new('manager', StringIO.new)}
  let(:manager)   { Manager.new(logger) }
  let(:messaging) { Messaging }
  let(:queues)    { %w(builds reporting.jobs) }

  let(:worker_1)  { worker('worker-1') }
  let(:worker_2)  { worker('worker-2') }
  let(:workers)   { [worker_1, worker_2] }

  def worker(name)
    stub(name, :boot => nil, :start => nil, :stop => nil)
  end

  before :each do
    messaging.stubs(:connect)
    messaging.stubs(:disconnect)
    messaging.stubs(:declare_queues)

    VirtualMachine::VirtualBox.stubs(:vm_names).returns(%w(travis-test-1 travis-test-2))
    Worker.stubs(:create).returns(*workers)
  end

  describe 'start' do
    it 'connects the messaging connection' do
      messaging.expects(:connect)
      manager.start
    end

    it 'declares the messaging queues' do
      messaging.expects(:declare_queues).with(*queues)
      manager.start
    end

    it 'starts the workers' do
      workers.each do |worker|
        worker.expects(:boot)
        worker.expects(:start)
      end
      manager.start
    end

    it 'returns itself' do
      manager.start.should == manager
    end

    describe 'logging' do
      it 'should log connecting the messaging connection' do
        manager.start
        logger.io.string.should =~ /:connect_messaging/
      end

      it 'should log declaring the queues' do
        manager.start
        logger.io.string.should =~ /:declare_queues/
      end

      it 'should log starting the workers' do
        manager.start
        logger.io.string.should =~ /:start_workers/
      end
    end
  end

  describe 'stop' do
    it 'stops the workers' do
      workers.each do |worker|
        worker.expects(:stop)
      end
      manager.stop
    end

    it 'disconnects the messaging connection' do
      messaging.expects(:disconnect)
      manager.stop
    end

    it 'returns itself' do
      manager.stop.should == manager
    end

    describe 'logging' do
      it 'should log stopping the workers' do
        manager.stop
        logger.io.string.should =~ /:stop_workers/
      end

      it 'should log disconnecting the messaging connection' do
        manager.stop
        logger.io.string.should =~ /:disconnect_messaging/
      end
    end
  end
end
