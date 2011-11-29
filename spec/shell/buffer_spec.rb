require 'spec_helper'

describe Travis::Worker::Shell::Buffer do
  it 'buffers' do
    result = []
    buffer = Travis::Worker::Shell::Buffer.new { |data| result << data }

    buffer << 'foo'
    buffer << 'bar'
    buffer.flush
    buffer << 'baz'
    buffer.flush

    result.should == ['foobar', 'baz']
  end
end
