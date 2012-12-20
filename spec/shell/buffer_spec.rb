require 'spec_helper'
require 'travis/worker/shell/buffer'

describe Travis::Worker::Shell::Buffer do
  let(:result) { [] }
  let(:buffer) { Travis::Worker::Shell::Buffer.new(nil, :limit => 10) { |data| result << data } }

  it 'buffers' do
    buffer << 'foo'
    buffer << 'bar'
    buffer.send(:flush)

    buffer << 'baz'
    buffer.send(:flush)

    result.should == ['foobar', 'baz']
  end

  it 'raises a OutputLimitExceeded exception when the log gets too long' do
    buffer << '12345'
    buffer << '12345'
    lambda { buffer << '12345' }.should raise_error(Travis::Build::OutputLimitExceeded)
  end
end
