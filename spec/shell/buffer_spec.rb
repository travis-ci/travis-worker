#encoding: UTF-8

require 'spec_helper'
require 'travis/worker/utils/buffer'

describe Travis::Worker::Utils::Buffer do
  let(:result) { [] }
  let(:buffer) { Travis::Worker::Utils::Buffer.new(nil) { |data| result << data } }

  it 'buffers' do
    buffer << 'foo'
    buffer << 'bar'
    buffer.send(:flush)

    buffer << 'baz'
    buffer.send(:flush)

    result.should == ['foobar', 'baz']
  end

  it 'raises a OutputLimitExceeded exception when the log gets too long' do
    buffer.expects(:bytes_limit).at_least_once.returns(10)
    buffer << '12345'
    buffer << '12345'
    lambda { buffer << '12345' }.should raise_error(Travis::Worker::Utils::Buffer::OutputLimitExceededError)
  end
end
