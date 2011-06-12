require 'test_helper'

class ShellBufferTest < Test::Unit::TestCase
  include Travis

  Shell::Buffer.send :public, *Shell::Buffer.protected_instance_methods

  attr_reader :buffer

  def setup
    super
  end

  test 'buffers' do
    result = []
    buffer = Shell::Buffer.new { |data| result << data }

    buffer << 'foo'
    buffer << 'bar'
    buffer.flush
    buffer << 'baz'
    buffer.flush

    assert_equal ['foobar', 'baz'], result
  end

end


