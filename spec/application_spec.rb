require 'spec_helper'
require 'stringio'

describe Application do
  let(:commands)    { stub('commands', :subscribe => nil) }
  let(:logger)      { Logger.new('manager', StringIO.new)}
  let(:manager)     { stub('manager', :start => nil) }
  let(:application) { Application.new }

  before :each do
    Amqp.stubs(:commands).returns(commands)
    application.stubs(:manager).returns(manager)
    application.stubs(:logger).returns(logger)
  end

  describe 'run' do
    it 'subscribes to the amqp commands queue' do
      commands.expects(:subscribe)
      application.run
    end

    it 'subscribes to the amqp commands queue' do
      commands.expects(:subscribe)
      application.run
    end
  end

  describe 'process' do
    let(:message) { stub('message', :ack => nil) }
    let(:payload) { '{ "command": "stop", "workers": ["worker-1", "worker-2"], "force": true }' }

    it 'accepts a :stop command and stops' do
      manager.expects(:stop).with(:workers => %w(worker-1 worker-2), :force => true)
      application.send(:process, message, payload)
    end
  end

  describe 'decode' do
    it 'decodes the json payload' do
      hashr = application.send(:decode, '{ "foo": "bar" }')
      hashr.foo.should == 'bar'
    end

    it 'defaults :workers to an empty array' do
      hashr = application.send(:decode, '{}')
      hashr.workers.should == []
    end
  end
end

