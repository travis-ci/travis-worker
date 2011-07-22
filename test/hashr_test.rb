require 'test_helper'

class HashrTest < Test::Unit::TestCase
  include Travis::Worker

  def teardown
    ENV.keys.select { |key| key =~ /^WORKER_/ }.each { |key| ENV.delete(key) }
  end

  test 'method access on an existing key returns the value' do
    assert_equal 'foo', Hashr.new({ :foo => 'foo' }).foo
  end

  test 'method access on a non-existing key returns nil' do
    assert_nil Hashr.new({ :foo => 'foo' }).bar
  end

  test 'method access on an existing nested key returns the value' do
    assert_equal 'bar', Hashr.new({ :foo => { :bar => 'bar' } }).foo.bar
  end

  test 'method access on a non-existing nested key returns nil' do
    assert_nil Hashr.new({ :foo => { :bar => 'bar' } }).foo.baz
  end

  test 'method access with a question mark returns true if the key has a value' do
    assert_equal true, Hashr.new({ :foo => { :bar => 'bar' } }).foo.bar?
  end

  test 'method access with a question mark returns false if the key does not have a value' do
    assert_equal false, Hashr.new({ :foo => { :bar => 'bar' } }).foo.baz?
  end

  test 'defining defaults' do
    klass = Class.new(Hashr)
    klass.default(:foo => 'foo', :bar => { :baz => 'baz' })
    assert_equal 'foo', klass.new.foo
    assert_equal 'baz', klass.new.bar.baz
  end

  test 'defaults to env vars' do
    klass = Class.new(Hashr)
    klass.extend Hashr::EnvDefaults
    klass.default(:foo => 'foo', :bar => { :baz => 'baz' })

    ENV['WORKER_FOO'] = 'env foo'
    ENV['WORKER_BAR_BAZ'] = 'env bar baz'

    assert_equal 'env foo', klass.new.foo
    assert_equal 'env bar baz', klass.new.bar.baz
  end
end
