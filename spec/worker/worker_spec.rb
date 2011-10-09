require 'spec_helper'

describe Worker do
  let(:vm)        { stub('vm', :name => 'vm-name', :shell => nil, :prepare => nil)  }
  let(:queue)     { stub('queue', :subscribe => nil, :cancel_subscription => nil) }
  let(:worker)    { Worker.new(queue, vm) }
  let(:runner)    { stub('runner', :run => nil) }

  let(:message)   { stub('message', :ack => nil) }
  let(:payload)   { '{ "id": 1 }' }
  let(:exception) { Exception.new }

  before(:each) do
    Travis::Build::Job.stubs(:runner).returns(runner)
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
        worker.stubs(:process).raises(exception)
      end

      it 'responds to the error' do
        worker.expects(:error).with(exception, message)
        worker.work(message, payload)
      end

      it 'returns false' do
        worker.work(message, payload).should be_false
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
    it 'sets the logging header' do
      worker.send(:start, payload)
      Thread.current[:logging_header].should == 'vm-name'
    end

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
  end

  describe 'process' do
    it 'creates a new build job' do
      worker.jobs.expects(:create).returns(runner)
      worker.send(:process)
    end

    it 'runs the build job' do
      runner.expects(:run)
      worker.send(:process)
    end
  end
end
