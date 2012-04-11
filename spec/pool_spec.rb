require 'spec_helper'
require 'stringio'

describe Travis::Worker::Pool do
  let(:names)   { %w(worker-1 worker-2)}
  let(:connection)   { HotBunnies.connect(:hostname => "127.0.0.1") }


  let(:pool)    { Travis::Worker::Pool.new(names, Travis::Worker.config, connection) }
  let(:workers) { names.map { |name| stub(name, :name => name, :boot => nil, :start => nil, :stop => nil) } }

  before :each do
    Travis::Worker.stubs(:create).returns(*workers)
    pool.stubs(:quit)
  end

  describe 'start' do
    after :each do
      connection.close
    end

    describe 'with no worker names given' do
      it 'starts the workers' do
        workers.each { |worker| worker.expects(:start) }
        pool.start([])
      end
    end

    describe 'with a worker name given' do
      it 'starts the worker' do
        workers.first.expects(:start)
        pool.start(['worker-1'])
      end

      it 'does not start other workers' do
        workers.last.expects(:start).never
        pool.start(['worker-1'])
      end

      it 'raises WorkerNotFound if there is no worker with the given name' do
        lambda { pool.start(['worker-3']) }.should raise_error(Travis::WorkerNotFound)
      end
    end
  end

  describe 'stop' do
    describe 'with no worker names given' do
      after :each do
        connection.close
      end

      it 'stops the workers' do
        workers.each { |worker| worker.expects(:stop) }
        pool.stop([])
      end
    end

    describe 'with a worker name given' do
      after :each do
        connection.close
      end

      it 'stops the worker' do
        workers.first.expects(:stop)
        pool.stop(['worker-1'])
      end

      it 'does not start other workers' do
        workers.last.expects(:stop).never
        pool.stop(['worker-1'])
      end

      it 'raises WorkerNotFound if there is no worker with the given name' do
        lambda { pool.stop(['worker-3']) }.should raise_error(Travis::WorkerNotFound)
      end
    end

    describe 'with an option :force => true given' do
      after :each do
        connection.close
      end

      it 'stops the worker with that option' do
        workers.first.expects(:stop).with(:force => true)
        pool.stop(['worker-1'], :force => true)
      end
    end
  end
end
