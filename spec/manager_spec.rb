require 'spec_helper'
require 'stringio'

describe Manager do
  let(:worker_names) { %w(worker-1 worker-2)}
  let(:messaging)    { stub('messaging', :connect => nil, :disconnect => nil) }
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

    describe 'with no worker names given' do
      it 'starts the workers' do
        workers.each { |worker| worker.expects(:start) }
        manager.start
      end
    end

    describe 'with a worker name given' do
      it 'starts the worker' do
        workers.first.expects(:start)
        manager.start('worker-1')
      end

      it 'does not start other workers' do
        workers.last.expects(:start).never
        manager.start('worker-1')
      end

      it 'raises WorkerNotFound if there is no worker with the given name' do
        lambda { manager.start('worker-3') }.should raise_error(WorkerNotFound)
      end
    end

    it 'returns itself' do
      manager.start.should == manager
    end

    describe 'logging' do
      it 'should log connecting the messaging connection' do
        manager.start
        logger.io.string.should =~ /connect_messaging/
      end

      it 'should log starting the workers' do
        manager.start
        logger.io.string.should =~ /start_workers/
      end
    end
  end

  describe 'stop' do
    describe 'with no worker names given' do
      it 'stops the workers' do
        workers.each { |worker| worker.expects(:stop) }
        manager.stop
      end
    end

    describe 'with a worker name given' do
      it 'stops the worker' do
        workers.first.expects(:stop)
        manager.stop('worker-1')
      end

      it 'does not start other workers' do
        workers.last.expects(:stop).never
        manager.stop('worker-1')
      end

      it 'raises WorkerNotFound if there is no worker with the given name' do
        lambda { manager.stop('worker-3') }.should raise_error(WorkerNotFound)
      end
    end

    describe 'with an option :force => true given' do
      it 'stops the worker with that option' do
        workers.first.expects(:stop).with(:force => true)
        manager.stop('worker-1', :force => true)
      end
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
