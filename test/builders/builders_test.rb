require 'test_helper'
require 'hashr'

class BuildersTest < Test::Unit::TestCase

  def test_builder_for_returns_the_ruby_builder_if_language_is_empty
    builder = Travis::Worker::Builders.builder_for(Hashr.new)
    assert_equal(Travis::Worker::Builders::Ruby, builder)
  end

  def test_builder_for_returns_the_erlang_builder_if_language_equals_erlang
    builder = Travis::Worker::Builders.builder_for(Hashr.new({ :language => :erlang }))
    assert_equal(Travis::Worker::Builders::Erlang, builder)
  end

  def test_builder_for_raises_an_error_if_language_isnt_recognized
    assert_raises(NameError) do
      Travis::Worker::Builders.builder_for(Hashr.new({ :language => :foobar }))
    end
  end

end