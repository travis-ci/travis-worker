require 'test_helper'
require 'hashr'

class BuilderBaseTest < Test::Unit::TestCase

  def new_builder(config = {})
    Travis::Worker::Builders::Base.new(config)
  end

  def test_new_sets_the_config
    builder = new_builder
    assert_equal({}, builder.config)
  end

end