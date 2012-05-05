require 'spec_helper'

describe Travis::Worker::Reporters::LogStreamer do
  include_context "hot_bunnies connection"

  let(:channel)     { connection.create_channel }
  let(:routing_key) { "reporting.jobs.builds.jvmotp" }
  let(:queue)       { channel.queue(routing_key, :durable => true) }
  let(:reporting_exchange) { channel.exchange("reporting", :type => :topic, :durable => true) }
  let(:reporter)    { described_class.new('staging-1', connection.create_channel, routing_key) }

  include Travis::Serialization

  describe 'notify' do
    before :each do
      queue.purge
      queue.bind(reporting_exchange, :routing_key => routing_key)
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
