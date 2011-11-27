require 'spec_helper'
require 'stringio'

describe Application do
  let(:commands)    { stub('commands', :subscribe => nil) }
  let(:manager)     { stub('manager', :start => nil, :ready? => true) }
  let(:application) { Application.new }

  before :each do
    Amqp::Consumer.stubs(:commands).returns(commands)
    application.stubs(:manager).returns(manager)
    application.stubs(:logger).returns(Logger.new(StringIO.new))
    application.stubs(:reply)
  end

  describe 'boot' do
    it 'subscribes to the amqp commands queue' do
      commands.expects(:subscribe)
      application.boot
    end

    it 'subscribes to the amqp commands queue' do
      commands.expects(:subscribe)
      application.boot
    end
  end

  describe 'process' do
    let(:message) { stub('message', :ack => nil, :properties => stub(:message_id => 1)) }

    it 'accepts a :stop command and stops' do
      payload = '{ "command": "stop", "workers": ["worker-1", "worker-2"], "force": true }'
      manager.expects(:stop).with(:workers => %w(worker-1 worker-2), :force => true)
      application.send(:process, message, payload)
    end

    it 'accepts a :config command and fetches the config' do
      payload = '{ "command": "config" }'
      manager.expects(:config).with()
      application.send(:process, message, payload)
    end
  end
end

