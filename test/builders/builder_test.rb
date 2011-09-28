require 'test_helper'
require 'hashr'

class BuilderTest < Test::Unit::TestCase

  def setup
    Travis::Worker.stubs(:config).returns(Hashr.new)
  end

  def test_create_returns_the_ruby_builder_if_language_is_empty
    builder = Travis::Worker::Builder.create(Hashr.new)
    assert_equal(Travis::Worker::Builder::Ruby, builder)
  end

  def test_create_returns_the_nodejs_builder_if_language_equals_javascript_with_nodejs
    builder = Travis::Worker::Builder.create(Hashr.new({ :language => :nodejs }))
    assert_equal(Travis::Worker::Builder::NodeJs, builder)
    builder = Travis::Worker::Builder.create(Hashr.new({ :language => "node.js".to_sym }))
    assert_equal(Travis::Worker::Builder::NodeJs, builder)
  end

  def test_create_returns_the_erlang_builder_if_language_equals_erlang
    builder = Travis::Worker::Builder.create(Hashr.new({ :language => :erlang }))
    assert_equal(Travis::Worker::Builder::Erlang, builder)
  end

  def test_create_returns_the_erlang_builder_if_lanuage_is_empty_and_worker_config_defines_it
    Travis::Worker.stubs(:config).returns(Hashr.new(:default_language => 'erlang'))
    builder = Travis::Worker::Builder.create(Hashr.new)
    assert_equal(Travis::Worker::Builder::Erlang, builder)
  end

  def test_create_raises_an_error_if_language_isnt_recognized
    assert_raises(NameError) do
      Travis::Worker::Builder.create(Hashr.new({ :language => :foobar }))
    end
  end

end
