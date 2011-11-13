require 'spec_helper'
require 'stringio'

describe Manager do
  let(:names)    { %w(worker-1 worker-2)}
  let(:commands) { stub('commands', :subscribe => nil) }
  let(:amqp)     { stub('amqp', :connect => nil, :disconnect => nil, :commands => commands) }
  let(:logger)   { Logger.new('manager', StringIO.new)}
  let(:manager)  { Manager.new(names, amqp, logger, {}) }

  let(:queues)  { %w(builds reporting.jobs) }
  let(:workers) { names.map { |name| stub(name, :name => name, :boot => nil, :start => nil, :stop => nil) } }

  before :each do
    Worker.stubs(:create).returns(*workers)
    manager.stubs(:quit)
  end

  describe 'start' do
    describe 'with no worker names given' do
      it 'starts the workers' do
        workers.each { |worker| worker.expects(:start) }
        manager.start
      end
    end

    describe 'with a worker name given' do
      it 'starts the worker' do
        workers.first.expects(:start)
        manager.start(:workers => ['worker-1'])
      end

      it 'does not start other workers' do
        workers.last.expects(:start).never
        manager.start(:workers => ['worker-1'])
      end

      it 'raises WorkerNotFound if there is no worker with the given name' do
        lambda { manager.start(:workers => ['worker-3']) }.should raise_error(WorkerNotFound)
      end
    end

    describe 'logging' do
      it 'should log starting the workers' do
        manager.start
        logger.io.string.should =~ /start/
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
        manager.stop(:workers => ['worker-1'])
      end

      it 'does not start other workers' do
        workers.last.expects(:stop).never
        manager.stop(:workers => ['worker-1'])
      end

      it 'raises WorkerNotFound if there is no worker with the given name' do
        lambda { manager.stop(:workers => ['worker-3']) }.should raise_error(WorkerNotFound)
      end
    end

    describe 'with an option :force => true given' do
      it 'stops the worker with that option' do
        workers.first.expects(:stop).with(:force => true)
        manager.stop(:workers => ['worker-1'], :force => true)
      end
    end

    describe 'logging' do
      it 'should log stopping the workers' do
        manager.stop
        logger.io.string.should =~ /stop/
      end
    end
  end
end
