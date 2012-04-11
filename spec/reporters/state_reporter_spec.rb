require 'spec_helper'

describe Travis::Worker::Reporters::StateReporter do
  include_context "hot_bunnies connection"

  let(:reporter)   { described_class.new('staging-1', connection.create_channel) }
  let(:logger)     { stub('logger', :before => nil, :after => nil) }
  let(:io)         { StringIO.new }

  let(:channel) { connection.create_channel }
  let(:queue)   { channel.queue("reporting.workers", :durable => true) }

  include Travis::Serialization


  before :each do
    Travis.logger = Logger.new(io)
    Travis.logger.level = Logger::DEBUG
  end

  describe 'notify' do
    before :each do
      queue.purge
    end
    after :each do
      connection.close
    end

    it "publishes notifications of given type" do
      reporter.notify('build:started', :hostname => "giove.local")
      sleep 0.5
      meta, payload = queue.get

      decode(payload).should == { :hostname => "giove.local" }
      meta.properties.type.should == "build:started"
    end
  end

  describe 'logging' do
    after :each do
      connection.close
    end

    it 'logs before :message is being called' do
      reporter.notify('build:started', :foo => "bar")
      io.string.should include('about to message')
    end
  end
end
