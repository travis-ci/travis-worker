require 'spec_helper'
require 'stringio'

describe Application do
  let(:commands)    { stub('commands', :subscribe => nil) }
  let(:logger)      { Logger.new('manager', StringIO.new)}
  let(:manager)     { stub('manager', :start => nil, :ready? => true) }
  let(:application) { Application.new }

  before :each do
    Amqp::Consumer.stubs(:commands).returns(commands)
    application.stubs(:manager).returns(manager)
    application.stubs(:logger).returns(logger)
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
    let(:payload) { '{ "command": "stop", "workers": ["worker-1", "worker-2"], "force": true }' }

    it 'accepts a :stop command and stops' do
      manager.expects(:stop).with(:workers => %w(worker-1 worker-2), :force => true)
      application.send(:process, message, payload)
    end
  end
end

