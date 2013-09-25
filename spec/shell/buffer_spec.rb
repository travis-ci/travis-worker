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

  it 'limits each part to given "chunk_size", taking json conversion into account' do
    buffer = Travis::Worker::Utils::Buffer.new(nil, :limit => 20, :chunk_size => 5) { |data| result << data }

    buffer << '1ą234512345'
    buffer.send(:flush)

    result.should == ["1", "ą", "234", "512", "345"]
  end
end
