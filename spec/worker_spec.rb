require 'spec_helper'
require 'stringio'

describe Worker do
  let(:vm)        { stub('vm', :name => 'vm-name', :shell => nil, :prepare => nil)  }
  let(:queue)     { stub('queue', :subscribe => nil, :cancel_subscription => nil) }
  let(:reporter)  { stub('reporter') }
  let(:logger)    { Util::Logging::Logger.new(vm.name) }
  let(:config)    { Hashr.new }
  let(:worker)    { Worker.new(vm, queue, reporter, logger, config) }

  let(:message)   { stub('message', :ack => nil) }
  let(:payload)   { '{ "id": 1 }' }
  let(:exception) { Exception.new }
  let(:build)     { stub('build', :run => nil) }

  before(:each) do
    Util::Logging.io = StringIO.new
    Travis::Build.stubs(:create).returns(build)
  end

  describe 'boot' do
    it 'sets the current state to :booting while it prepares the vm' do
      state = nil
      vm.stubs(:prepare).with { state = worker.state } # hrmm, mocha doesn't support spies, does it?
      worker.boot
      state.should == :booting
    end

    it 'prepares the vm' do
      vm.expects(:prepare)
      worker.boot
    end

    it 'subscribes to the builds queue' do
      queue.expects(:subscribe)
      worker.boot
    end

    it 'sets the current state to :waiting' do
      worker.boot
      worker.state.should == :waiting
    end
  end

  describe 'work' do
    describe 'without any exception rescued' do
      before :each do
        worker.state = :waiting
      end

      it 'starts working' do
        worker.expects(:start)
        worker.work(message, payload)
      end

      it 'processes the current payload' do
        worker.expects(:process)
        worker.work(message, payload)
      end

      it 'finishes' do
        worker.expects(:finish)
        worker.work(message, payload)
      end

      it 'returns true' do
        worker.work(message, payload).should be_true
      end
    end

    describe 'with an exception rescued' do
      let(:exception) { Exception.new }

      before :each do
        worker.state = :waiting
        worker.stubs(:process).raises(exception)
      end

      it 'responds to the error' do
        worker.expects(:error).with(exception, message)
        worker.work(message, payload)
      end

      it 'raises WorkerError' do
        lambda {
          worker.work(message, payload)
        }.should raise_error Worker::WorkerError
      end
    end
  end

  describe 'stop' do
    it 'unsubscribes from the builds queue' do
      queue.expects(:cancel_subscription)
      worker.stop
    end

    it 'sets the current state to :stopped' do
      worker.stop
      worker.state.should == :stopped
    end
  end

  describe 'start' do
    it 'sets the current payload' do
      worker.send(:start, payload)
      worker.payload.should == { :id => 1 }
    end

    it 'sets the current state to :working' do
      worker.send(:start, payload)
      worker.state.should == :working
    end
  end

  describe 'finish' do
    it 'unsets the current payload' do
      worker.send(:start, '{ "id": 1 }') # TODO should use an attr_accessor
      worker.send(:finish, message)
      worker.payload.should be_nil
    end

    it 'acknowledges the message' do
      message.expects(:ack)
      worker.send(:finish, message)
    end
  end

  describe 'error' do
    it 'requeues the message' do
      message.expects(:ack).with(:requeue => true)
      lambda {
        worker.send(:error, exception, message)
      }.should raise_error Worker::WorkerError
    end

    it 'stores the error' do
      lambda {
        worker.send(:error, exception, message)
      }.should raise_error Worker::WorkerError
      worker.last_error.should == exception
    end

    it 'stops itself' do
      worker.expects(:stop)
      lambda {
        worker.send(:error, exception, message)
      }.should raise_error Worker::WorkerError
    end
  end

  describe 'process' do
    it 'creates a new build job' do
      Travis::Build.expects(:create).returns(build)
      worker.send(:process)
    end

    it 'runs the build job' do
      build.expects(:run)
      worker.send(:process)
    end
  end
end
