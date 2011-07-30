require 'test_helper'

class JobRepositoryConfigTest < Test::Unit::TestCase
  include Travis::Worker::Job

  Config = Repository::Config
  Config.send :public, *Config.protected_instance_methods(false)

  def setup
    Config.any_instance.stubs(:evaluate).with('pwd', anything).returns('/path/to/current/directory')
  end

  test 'rvm returns an rvm string when it holds an array with an rvm string' do
    config = Config.new('rvm' => ['1.9.2'])
    assert_equal '1.9.2', config.rvm
  end

  test 'gemfile prepends the current working directory to the given relative Gemfile path (given as string)' do
    config = Config.new('gemfile' => 'gemfiles/rails-3.1.0')
    assert_equal '/path/to/current/directory/gemfiles/rails-3.1.0', config.gemfile
  end

  test 'gemfile prepends the current working directory to the given relative Gemfile path (given as array)' do
    config = Config.new('gemfile' => ['gemfiles/rails-3.1.0'])
    assert_equal '/path/to/current/directory/gemfiles/rails-3.1.0', config.gemfile
  end

  test 'gemfile? returns true if a Gemfile exists in the current working directory (default gemfile)' do
    config = Config.new
    config.stubs(:exec).with('test -f /path/to/current/directory/Gemfile', anything).returns(true)
    assert config.gemfile?
  end

  test 'gemfile? returns true if a Gemfile exists in the current working directory (custom gemfile, given as string)' do
    config = Config.new('gemfile' => 'gemfiles/rails-3.1.0')
    config.stubs(:exec).with('test -f /path/to/current/directory/gemfiles/rails-3.1.0', anything).returns(true)
    assert config.gemfile?
  end

  test 'gemfile? returns true if a Gemfile exists in the current working directory (custom gemfile, given as array)' do
    config = Config.new('gemfile' => ['gemfiles/rails-3.1.0'])
    config.stubs(:exec).with('test -f /path/to/current/directory/gemfiles/rails-3.1.0', anything).returns(true)
    assert config.gemfile?
  end

  test 'script, before_script and after_script return the given :before_script and :after_script values' do
    config = Config.new(:script => 'script', :before_script => 'before script', :after_script => 'after script')
    assert_equal 'script', config.script
    assert_equal 'before script', config.before_script
    assert_equal 'after script', config.after_script
  end

  test 'script defaults to "rake" when there is no Gemfile' do
    config = Config.new
    config.stubs(:gemfile?).returns(false)
    assert_equal 'rake', config.script
  end

  test 'script defaults to "bundle exec rake" when there is a Gemfile' do
    config = Config.new
    config.stubs(:gemfile?).returns(true)
    assert_equal 'bundle exec rake', config.script
  end
end

