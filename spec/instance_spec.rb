require 'spec_helper'
require 'hot_bunnies'
require 'hashr'
require 'travis/worker/instance'
require 'celluloid/autostart'

describe Travis::Worker::Instance do
  include_context "hot_bunnies connection"

  let(:vm)           { stub('vm', :name => 'vm-name', :shell => nil, :prepare => nil, :sandboxed => nil)  }
  let(:queue_name)   { "builds.php" }
  
  let(:config)       { Hashr.new(:amqp => {}, :queue => queue_name, :timeouts => { :hard_timeout => 5 }) }

  let(:exception)    { stub('exception', :message => 'broken', :backtrace => ['kaputt.rb']) }


  let(:observer) { stub('observer', :notify) }
 
  def worker
    @worker ||= Travis::Worker::Instance.new('worker-1', vm, connection, queue_name, config, [observer]).wrapped_object
  end
  
  let(:metadata)        { stub('metadata', :ack => nil, :routing_key => "builds.common") }

  let(:decoded_payload) { Hashr.new('id' => 1, 'repository' => { 'slug' => 'joshk/fun_times' }, 'job' => { 'id' => 123 }, 'config' => { 'language' => 'ruby' }, 'uuid' => 'a-uuid') }
 
  let(:payload)         { MultiJson.encode(decoded_payload) }


  before :each do
    Travis::Worker.config.host = 'host'
    Celluloid.logger = nil
    Celluloid.shutdown; Celluloid.boot
    worker.stubs(:subscription).returns(stub(:cancelled? => false, :cancel => nil))
  end

  after :each do
    @worker = nil
  end


  describe 'start' do
    
    it 'sets the current state to :starting while it prepares the vm' do
      state = nil
      vm.stubs(:prepare).with { state = worker.state } # hrmm, mocha doesn't support spies, does it?
      worker.start
      state.should == :starting
    end

    it 'notifies the reporter about the :starting state' do
      observer.expects(:notify).with({ :name => 'worker-1', :host => 'host', :state => :starting, :payload => nil, :last_error => nil })
      worker.start
    end

    it 'prepares the vm' do
      vm.expects(:prepare)
      worker.start
    end

    it 'sets the current state to :ready' do
      worker.start
      worker.state.should eql(:ready)
    end

    it 'notifies the reporter about the :ready state' do
      observer.expects(:notify).with({ :name => 'worker-1', :host => 'host', :state => :ready, :payload => nil, :last_error => nil })
      worker.start
    end
  end

  describe 'stop' do
    after :each do
      worker.shutdown
    end

    before :each do
      worker.state = :foobarbaz
    end

    it 'sets the current state to :stopped' do
      worker.stop
      worker.state.should eql(:stopped)
    end

    it 'notifies the reporter about the :stopped state' do
      observer.expects(:notify).with({ :name => 'worker-1', :host => 'host', :state => :stopped, :payload => nil, :last_error => nil })
      worker.stop
    end
  end

  describe 'process' do
    describe 'without any exception rescued' do
      before(:each) { worker.state = :ready }
      after(:each)  { worker.shutdown }

      it 'works' do
        worker.expects(:work).with(metadata, payload)
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
      worker.stubs(:payload).returns(decoded_payload)
      metadata.stubs(:redelivered?).returns(false)
    end
    after(:each) do
      worker.shutdown
    end

    it 'prepares work' do
      worker.work(metadata, payload)
      worker.payload.should eql(decoded_payload)
      # Doesn't work, due to Travis.uuid being thread-specific in Celluloid
      Travis.uuid.should eql(decoded_payload['uuid'])
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
      worker.payload.should eql(nil)
    end

    it 'acknowledges the message' do
      metadata.expects(:ack)
      worker.send(:finish, metadata)
    end

    context "if the worker is working" do
      before(:each) { worker.state = :working }
      it 'sets the current state to :ready' do
        worker.send(:finish, metadata)
        worker.state.should eql(:ready)
      end
    end

    context "if the worker is stopping" do
      before(:each) { worker.state = :stopping }
      it 'sets the current state to :stopped' do
        worker.send(:finish, metadata)
        worker.state.should eql(:stopped)
      end
    end
  end

  describe 'error_build' do
    before(:each) do
      worker.stubs(:payload).returns(decoded_payload)
      worker.stubs(:sleep)
    end
    after(:each)  { worker.shutdown }

    it 'stores the error' do
      worker.send(:error_build, exception, metadata)
      worker.last_error.should eql([exception.message, exception.backtrace].flatten.join("\n"))
    end

    it 'calls finish' do
      worker.expects(:finish).with(metadata, restart: true)
      worker.send(:error_build, exception, metadata)
    end
  end
end
