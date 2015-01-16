require 'spec_helper'
require 'travis/worker/application/http_heart'

describe Travis::Worker::Application::HTTPHeart do
  let(:state) { { state: :up } }
  let(:heart) { Travis::Worker::Application::HTTPHeart.new('http://example.org', shutdown_block) }
  let(:shutdown_block) { ->(*) { state[:state] = :down } }
  let(:conn) { Excon.new('http://example.org', mock: true) }

  before :each do
    heart.stubs(:conn).returns(conn)
  end

  it 'stays up if the expected_state is up' do
    Excon.stub({}, {body: '{"expected_state":"up"}', status: 200})
    heart.beat
    expect(state[:state]).to eq(:up)
  end

  it 'shuts down if the expected_state is down' do
    Excon.stub({}, {body: '{"expected_state":"down"}', status: 200})
    heart.beat
    expect(state[:state]).to eq(:down)
  end
end
