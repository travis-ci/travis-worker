require 'spec_helper'
require 'hashr'
require 'stringio'

describe Travis::Worker do
  let(:vm)           { stub('vm', :name => 'vm-name', :shell => nil, :prepare => nil)  }
  let(:queue)        { stub('queue', :subscribe => nil, :unsubscribe => nil) }
  let(:reporter)     { stub('reporter') }
  let(:heart)        { stub('heart', :beat => nil, :stop => nil) }
  let(:config)       { Hashr.new }
  let(:worker)       { Travis::Worker.new('worker-1', vm, queue, reporter, config) }

  let(:message)      { stub('message', :ack => nil) }
  let(:payload)      { '{ "id": 1 }' }
  let(:exception)    { stub('exception', :message => 'broken', :backtrace => ['kaputt.rb']) }
  let(:build)        { stub('build', :run => nil) }
  let(:io)           { StringIO.new }

  before :each do
    Travis.logger = Logger.new(io)
    Travis::Build.stubs(:create).returns(build)
  end

  describe 'start' do
    it 'sets the current state to :starting while it prepares the vm' do
      state = nil
      vm.stubs(:prepare).with { state = worker.state } # hrmm, mocha doesn't support spies, does it?
      worker.start
      state.should == :starting
    end

    it 'starts the heartbeat' do
      worker.stubs(:heart).returns(heart)
      heart.expects(:beat)
      worker.start
    end

    it 'prepares the vm' do
      vm.expects(:prepare)
      worker.start
    end

    it 'subscribes to the builds queue' do
      queue.expects(:subscribe)
      worker.start
    end

    it 'sets the current state to :ready' do
      worker.start
      worker.should be_ready
    end
  end

  describe 'stop' do
    it 'unsubscribes from the builds queue' do
      queue.expects(:unsubscribe)
      worker.stop
    end

    it 'sets the current state to :stopping if the worker is still working' do
      worker.stubs(:working?).returns(true)
      worker.stop
      worker.should be_stopping
    end

    it 'sets the current state to :stopped if the worker is not working' do
      worker.stubs(:working?).returns(false)
      worker.stop
      worker.should be_stopped
    end
  end

  describe 'process' do
    describe 'without any exception rescued' do
      before :each do
        worker.state = :ready
      end

      it 'works' do
        worker.expects(:work)
        worker.send(:process, message, payload)
      end
    end

    describe 'with an exception rescued' do
      let(:exception) { Exception.new }

      before :each do
        worker.state = :ready
        worker.stubs(:work).raises(exception)
      end

      it 'responds to the error' do
        worker.expects(:error).with(exception, message)
        worker.send(:process, message, payload)
      end
    end
  end

  describe 'work' do
    before :each do
      worker.state = :ready
    end

    it 'prepares work' do
      worker.expects(:prepare)
      worker.send(:work, message, payload)
    end

    it 'creates a new build job' do
      Travis::Build.expects(:create).returns(build)
      worker.send(:work, message, payload)
    end

    it 'runs the build' do
      build.expects(:run)
      worker.send(:work, message, payload)
    end

    it 'finishes' do
      worker.expects(:finish)
      worker.send(:work, message, payload)
    end
  end

  describe 'prepare' do
    it 'sets the current payload' do
      worker.send(:prepare, payload)
      worker.payload.should == { :id => 1 }
    end

    it 'sets the current state to :working' do
      worker.send(:prepare, payload)
      worker.should be_working
    end
  end

  describe 'finish' do
    it 'unsets the current payload' do
      worker.send(:prepare, '{ "id": 1 }')
      worker.send(:finish, message)
      worker.payload.should be_nil
    end

    it 'acknowledges the message' do
      message.expects(:ack)
      worker.send(:finish, message)
    end

    it 'sets the current state to :read if the worker is working'
    it 'sets the current state to :stopped if the worker is stopping'
  end

  describe 'error' do
    it 'requeues the message' do
      message.expects(:ack).with(:requeue => true)
      worker.send(:error, exception, message)
    end

    it 'stores the error' do
      worker.send(:error, exception, message)
      worker.last_error.should == exception
    end

    it 'stops itself' do
      worker.expects(:stop)
      worker.send(:error, exception, message)
    end

    it 'sets the current state to :errored' do
      worker.send(:error, exception, message)
      worker.should be_errored
    end
  end
end
