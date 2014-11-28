require 'spec_helper'
require 'stringio'
require 'travis/worker/application'

describe Travis::Worker::Application do
  let(:app)     { Travis::Worker::Application.new }
  let(:workers) { stub('workers', :start => nil, :stop => nil) }
  let(:heart)   { stub('heart', :beat => nil, :stop => nil) }

  before :each do
    app.stubs(:heart).returns(heart)
    app.stubs(:workers).returns(workers)
    app.stubs(:logger).returns(Logger.new(StringIO.new))
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
      expect(app.status).to eq(:result)
    end
  end

  describe 'set' do
    after :each do
      Travis::Worker.config.delete(:foo)
    end

    it 'sets the given configuration to Travis.config' do
      app.set('foo.bar.baz' => 1)
      expect(Travis::Worker.config.foo.bar.baz).to eq(1)
    end
  end

  describe 'logging' do
    let(:io) { StringIO.new }

    before :each do
      Travis.logger = Logger.new(io)
    end

    it 'logs starting the workers' do
      app.start
      expect(io.string).to match(/start/)
    end

    it 'logs stopping the workers' do
      app.stop()
      expect(io.string).to match(/stop/)
    end

    it 'includes the process id' do
      Travis.logger.info('foo')
      expect(io.string).to match(/ PID=\d+ /)
    end

    it 'includes the thread id' do
      Travis.logger.info('foo')
      expect(io.string).to match(/ TID=\d+ /)
    end
  end
end

