require 'spec_helper'
require 'travis/worker/application/commands/dispatcher'

describe Travis::Worker::Application::Commands::Dispatcher do
  describe 'start' do
    let(:amqp_connection) { stub('connection', create_channel: amqp_channel) }
    let(:amqp_channel) { stub('channel', :prefetch= => nil, :queue => amqp_queue, :fanout => nil) }
    let(:amqp_queue) { stub('queue', bind: nil, subscribe: amqp_consumer) }
    let(:amqp_consumer) { stub('consumer', cancel!: nil, shutdown!: nil) }
    let(:pool) { stub('pool') }

    before do
      Travis::Amqp.expects(:connection).returns(amqp_connection)
    end

    it 'subscribes to a queue' do
      amqp_queue.expects(:subscribe)
      described_class.new(pool).start
    end
  end
end
