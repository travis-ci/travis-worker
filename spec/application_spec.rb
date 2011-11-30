require 'spec_helper'
require 'stringio'

describe Travis::Worker::Application do
  let(:app)     { Travis::Worker::Application.new }
  let(:workers) { stub('workers', :start => nil, :stop => nil) }
  let(:heart)   { stub('heart', :beat => nil, :stop => nil) }

  before :each do
    app.stubs(:heart).returns(heart)
    app.stubs(:workers).returns(workers)
    app.stubs(:logger).returns(Logger.new(StringIO.new))
    Travis::Worker::Application::Command.stubs(:subscribe)
  end

  describe 'boot' do
    before :each do
      Signal.stub(:trap)
    end

    it 'configures the log level' do
      Logger.stubs(:const_get).returns(Logger::INFO)
      app.boot
      Travis.logger.level.should == Logger::INFO
    end

    it 'installs signal traps' do
      Signal.expects(:trap).twice
      app.boot
    end

    it 'starts the given workers' do
      workers.expects(:start).with(['worker-1'])
      app.boot(:workers => ['worker-1'])
    end

    it 'starts the heartbeat' do
      heart.expects(:beat)
      app.boot
    end

    it 'subscribes to the command queue' do
      Travis::Worker::Application::Command.expects(:subscribe).with(app)
      app.boot
    end
  end

  describe 'start' do
    it 'starts the workers with the given names' do
      workers.expects(:start).with(['worker-1'])
      app.start(:workers => ['worker-1'])
    end
  end

  describe 'stop' do
    it 'stops the workers with the given names and options' do
      workers.expects(:stop).with(['worker-1'], :force => true)
      app.stop(:workers => ['worker-1'], :force => true)
    end
  end

  describe 'status' do
    it 'returns the workers status report' do
      workers.expects(:status).returns(:result)
      app.status.should == :result
    end
  end

  describe 'set' do
    after :each do
      Travis::Worker.config.delete(:foo)
    end

    it 'sets the given configuration to Travis.config' do
      app.set('foo.bar.baz' => 1)
      Travis::Worker.config.foo.bar.baz.should == 1
    end
  end

  describe 'terminate' do
    before :each do
      java.lang.System.stubs(:exit)
      Travis::Amqp.stubs(:disconnect)
      app.stubs(:sleep)
      app.stubs(:system)
    end

    it 'stops the given workers' do
      workers.expects(:stop).with(['worker-1'], :force => true)
      app.terminate(:workers => ['worker-1'], :force => true)
    end

    it 'disconnects from amqp' do
      Travis::Amqp.expects(:disconnect)
      app.terminate
    end

    it 'stops the heartbeat' do
      heart.expects(:stop)
      app.terminate
    end

    describe 'given :update => true' do
      it 'resets the current git working directory' do
        app.expects(:system).with('git reset --hard > log/worker.log')
        app.terminate(:update => true)
      end

      it 'updates the code base' do
        app.expects(:system).with('git pull > log/worker.log')
        app.terminate(:update => true)
      end

      it 'installs the bundle' do
        app.expects(:system).with('bundle install > log/worker.log')
        app.terminate(:update => true)
      end
    end

    describe 'given :reboot => true' do
      it 'schedules a system job for restarting the application' do
        app.expects(:system).with('echo "thor travis:worker:boot >> log/worker.log" | at now')
        app.terminate(:reboot => true)
      end
    end

    it 'quits' do
      java.lang.System.expects(:exit)
      app.terminate
    end
  end

  describe 'logging' do
    let(:io) { StringIO.new }

    before :each do
      Travis.logger = Logger.new(io)
    end

    it 'should log starting the workers' do
      app.start
      io.string.should =~ /start/
    end

    it 'should log stopping the workers' do
      app.stop()
      io.string.should =~ /stop/
    end
  end
end

