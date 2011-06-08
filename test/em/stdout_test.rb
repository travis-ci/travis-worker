require 'test_helper'
require 'em/stdout'

STDOUT.sync = true

class EMStdoutTest < Test::Unit::TestCase
  def setup
    EM::Stdout.output = false
  end

  def teardown
    EM::Stdout.output = true
  end

  test 'splitting stdout' do
    result = nil
    within_em_loop do
      EM.split_stdout do |c|
        c.callback { |data| result = data }
      end
      print 'foo'
      # sleep(1)
      # assert_equal 'foo', result
    end
    assert_equal 'foo', result
  end
end

