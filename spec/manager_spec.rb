require 'spec_helper'
require 'stringio'

describe Manager do
  let(:worker_names) { %w(worker-1 worker-2)}
  let(:messaging)    { stub('messaging', :connect => nil, :disconnect => nil, :declare_queues => nil) }
  let(:logger)       { Util::Logging::Logger.new('manager', StringIO.new)}
  let(:manager)      { Manager.new(worker_names, messaging, logger, {}) }

  let(:queues)       { %w(builds reporting.jobs) }
  let(:workers)      { worker_names.map { |name| stub(name, :name => name, :boot => nil, :start => nil, :stop => nil) } }

  before :each do
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
      workers.each { |worker| worker.expects(:boot) }
      manager.start
    end

    it 'returns itself' do
      manager.start.should == manager
    end

    describe 'logging' do
      it 'should log connecting the messaging connection' do
        manager.start
        logger.io.string.should =~ /connect_messaging/
      end

      it 'should log declaring the queues' do
        manager.start
        logger.io.string.should =~ /declare_queues/
      end

      it 'should log starting the workers' do
        manager.start
        logger.io.string.should =~ /start_workers/
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
        logger.io.string.should =~ /stop_workers/
      end

      it 'should log disconnecting the messaging connection' do
        manager.stop
        logger.io.string.should =~ /disconnect_messaging/
      end
    end
  end
end
