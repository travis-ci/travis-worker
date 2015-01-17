require 'spec_helper'
require 'travis/worker/application/http_heart'

describe Travis::Worker::Application::HTTPHeart do
  let(:state) { { state: :up } }
  let(:heart) { Travis::Worker::Application::HTTPHeart.new('http://example.org', shutdown_block) }
  let(:shutdown_block) { ->(*) { state[:state] = :down } }

  it 'stays up if the expected_state is up' do
    stub_request(:post, 'http://example.org').to_return(body: '{"expected_state":"up"}', status: 200)
    heart.beat
    expect(state[:state]).to eq(:up)
  end

  it 'shuts down if the expected_state is down' do
    stub_request(:post, 'http://example.org').to_return(body: '{"expected_state":"down"}', status: 200)
    heart.beat
    expect(state[:state]).to eq(:down)
  end
end
