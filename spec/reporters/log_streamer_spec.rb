require 'spec_helper'

describe Travis::Worker::Reporters::LogStreamer do
  let(:connection) { HotBunnies.connect(:hostname => "127.0.0.1") }
  let(:channel) { connection.create_channel }
  let(:routing_key) do
    "reporting.jobs.builds.jvmotp"
  end
  let(:queue) do
    channel.queue(routing_key, :durable => true)
  end
  let(:reporting_exchange) do
    channel.exchange("reporting", :type => :topic, :durable => true)
  end

  let(:reporter)   { described_class.new('staging-1', connection.create_channel, routing_key) }

  include Travis::Serialization


  describe 'notify' do
    before :each do
      queue.purge

      queue.bind(reporting_exchange, :routing_key => routing_key)
    end
    after :each do
      connection.close
    end

    it "publishes log chunks" do
      reporter.notify('build:log', :log => "...")
      sleep 0.5
      meta, payload = queue.get

      decode(payload).should == { :log => "..." }
      meta.properties.type.should == "build:log"
    end
  end
end
