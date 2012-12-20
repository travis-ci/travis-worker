require 'spec_helper'
require 'hashr'
require 'stringio'
require 'hot_bunnies'
require 'travis/worker/instance'

class DummyObserver
  attr_reader :events

  def initialize
    @events = []
  end

  def notify(event)
    @events << event
  end
end

describe Travis::Worker::Instance do
  include_context "hot_bunnies connection"

  let(:vm)           { stub('vm', :name => 'vm-name', :shell => nil, :prepare => nil)  }
  let(:observer)     { DummyObserver.new }
  let(:queue_name)   { "builds.php" }
  let(:config)       { Hashr.new(:amqp => {}, :queue => queue_name, :timeouts => { :hard_timeout => 5 }) }

  let(:worker)       { Travis::Worker::Instance.new('worker-1', vm, connection, queue_name, config, observer).wrapped_object }

  let(:metadata)        { stub('metadata', :ack => nil, :routing_key => "builds.common") }
  let(:decoded_payload) { { 'id' => 1, 'repository' => { 'slug' => 'joshk/fun_times' }, 'job' => { 'id' => 123 } } }
  let(:payload)         { MultiJson.encode(decoded_payload) }

  let(:exception)    { stub('exception', :message => 'broken', :backtrace => ['kaputt.rb']) }
  let(:build)        { stub('build', :run => nil) }
  let(:io)           { StringIO.new }

  before :each do
    Socket.stubs(:gethostname).returns('host')
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

    it 'notifies the reporter about the :starting state' do
      worker.start
      observer.events.should include({ :name => 'worker-1', :host => 'host', :state => :starting, :payload => nil, :last_error => nil })
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
      worker.start
      observer.events.should include({ :name => 'worker-1', :host => 'host', :state => :ready, :payload => nil, :last_error => nil })
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
        worker.stop
        observer.events.should include({ :name => 'worker-1', :host => 'host', :state => :stopping, :payload => nil, :last_error => nil })
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
        worker.stop
        observer.events.should include({ :name => 'worker-1', :host => 'host', :state => :stopped, :payload => nil, :last_error => nil })
      end
    end
  end

  describe 'process' do
    describe 'without any exception rescued' do
      before(:each) { worker.state = :ready }
      after(:each)  { worker.shutdown }

      it 'works' do
        worker.expects(:work)
        worker.process(metadata, payload)
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
        worker.expects(:error_build).with(exception, metadata)
        worker.process(metadata, payload)
      end
    end
  end

  describe 'work' do
    before(:each) do
      worker.state = :ready
      metadata.stubs(:redelivered?).returns(false)
    end
    after(:each) do
      worker.shutdown
    end

    it 'prepares work' do
      worker.stubs(:payload => decoded_payload)
      worker.expects(:prepare)
      worker.work(metadata, payload)
    end

    it 'creates a new build job' do
      Travis::Build.expects(:create).returns(build)
      worker.work(metadata, payload)
    end

    it 'runs the build' do
      build.expects(:run)
      worker.work(metadata, payload)
    end

    it 'finishes' do
      worker.expects(:finish)
      worker.work(metadata, payload)
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
      worker.send(:error_build, exception, metadata)
    end

    it 'stores the error' do
      worker.send(:error_build, exception, metadata)
      worker.last_error.should == "broken\nkaputt.rb"
    end

    it 'stops itself' do
      worker.expects(:stop)
      worker.send(:error_build, exception, metadata)
    end

    it 'sets the current state to :errored' do
      worker.send(:error_build, exception, metadata)
      worker.should be_errored
    end
  end
end
