require 'spec_helper'
require 'hashr'
require 'stringio'
require "hot_bunnies"

describe Travis::Worker do
  include_context "hot_bunnies connection"

  let(:vm)           { stub('vm', :name => 'vm-name', :shell => nil, :prepare => nil)  }
  let(:reporter)     { stub('reporter', :notify => nil) }
  let(:queue_names)  { %w(builds.php builds.python builds.perl) }
  let(:config)       { Hashr.new(:amqp => {}, :queues => queue_names) }

  let(:worker)       { Travis::Worker.new('worker-1', vm, connection, queue_names, config) }

  let(:metadata)     { stub('metadata', :ack => nil, :routing_key => "builds.common") }
  let(:payload)      { '{ "id": 1 }' }
  let(:exception)    { stub('exception', :message => 'broken', :backtrace => ['kaputt.rb']) }
  let(:build)        { stub('build', :run => nil) }
  let(:io)           { StringIO.new }

  before :each do
    Socket.stubs(:gethostname).returns('host')
    Travis.logger = Logger.new(io)
    Travis::Build.stubs(:create).returns(build)

    worker.state_reporter = reporter
  end

  describe 'start' do
    it 'sets the current state to :starting while it prepares the vm' do
      state = nil
      vm.stubs(:prepare).with { state = worker.state } # hrmm, mocha doesn't support spies, does it?
      worker.start
      state.should == :starting
    end

    it 'notifies the reporter about the :starting state' do
      reporter.expects(:notify).with('worker:status', :workers => [{ :name => 'worker-1', :host => 'host', :state => :starting, :payload => nil, :last_error => nil }])
      worker.start
    end

    it 'prepares the vm' do
      vm.expects(:prepare)
      worker.start
    end

    it 'sets the current state to :ready' do
      worker.start
      worker.should be_ready
    end

    it 'notifies the reporter about the :ready state' do
      reporter.expects(:notify).with('worker:status', :workers => [{ :name => 'worker-1', :host => 'host', :state => :ready, :payload => nil, :last_error => nil }])
      worker.start
    end
  end

  describe 'stop' do
    after :each do
      worker.shutdown
    end

    describe 'if the worker is still working' do
      before :each do
        worker.stubs(:working?).returns(true)
      end

      it 'sets the current state to :stopping ' do
        worker.stop
        worker.should be_stopping
      end

      it 'notifies the reporter about the :stopping state' do
        reporter.expects(:notify).with('worker:status', :workers => [{ :name => 'worker-1', :host => 'host', :state => :stopping, :payload => nil, :last_error => nil }])
        worker.stop
      end
    end

    describe 'if the worker is not working' do
      before :each do
        worker.stubs(:working?).returns(false)
      end

      it 'sets the current state to :stopped' do
        worker.stop
        worker.should be_stopped
      end

      it 'notifies the reporter about the :stopped state' do
        reporter.expects(:notify).with('worker:status', :workers => [{ :name => 'worker-1', :host => 'host', :state => :stopped, :payload => nil, :last_error => nil }])
        worker.stop
      end
    end
  end

  describe 'process' do
    describe 'without any exception rescued' do
      before(:each) { worker.state = :ready }
      after(:each)  { worker.shutdown }

      it 'works' do
        worker.expects(:work)
        worker.send(:process, metadata, payload)
      end
    end

    describe 'with an exception rescued' do
      let(:exception) { Exception.new }

      before :each do
        worker.state = :ready
        worker.stubs(:work).raises(exception)
      end

      after :each do
        worker.shutdown
      end

      it 'responds to the error' do
        worker.expects(:error).with(exception, metadata)
        worker.send(:process, metadata, payload)
      end
    end
  end

  describe 'work' do
    before(:each) { worker.state = :ready }
    after(:each)  { worker.shutdown }

    it 'prepares work' do
      worker.expects(:prepare)
      worker.send(:work, metadata, payload)
    end

    it 'creates a new build job' do
      Travis::Build.expects(:create).returns(build)
      worker.send(:work, metadata, payload)
    end

    it 'runs the build' do
      build.expects(:run)
      worker.send(:work, metadata, payload)
    end

    it 'finishes' do
      worker.expects(:finish)
      worker.send(:work, metadata, payload)
    end
  end

  describe 'prepare' do
    after(:each) { worker.shutdown }

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
    after(:each) { worker.shutdown }

    it 'unsets the current payload' do
      worker.send(:prepare, '{ "id": 1 }')
      worker.send(:finish, metadata)
      worker.payload.should be_nil
    end

    it 'acknowledges the message' do
      metadata.expects(:ack)
      worker.send(:finish, metadata)
    end

    context "if the worker is working" do
      it 'sets the current state to :ready'
    end

    context "if the worker is stopping" do
      it 'sets the current state to :stopped'
    end
  end

  describe 'error' do
    before(:each) { metadata.stubs(:reject) }
    after(:each)  { worker.shutdown }

    it 'requeues the message' do
      metadata.expects(:reject).with(:requeue => true)
      worker.send(:error, exception, metadata)
    end

    it 'stores the error' do
      worker.send(:error, exception, metadata)
      worker.last_error.should == "broken\nkaputt.rb"
    end

    it 'stops itself' do
      worker.expects(:stop)
      worker.send(:error, exception, metadata)
    end

    it 'sets the current state to :errored' do
      worker.send(:error, exception, metadata)
      worker.should be_errored
    end
  end
end
