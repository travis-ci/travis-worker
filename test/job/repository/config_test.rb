require 'test_helper'

class JobRepositoryConfigTest < Test::Unit::TestCase
  include Travis::Job

  Config = Repository::Config
  Config.send :public, *Config.protected_instance_methods(false)

  test 'gemfile prepends the current working directory to the given relative Gemfile path' do
    config = Config.new('gemfile' => 'gemfiles/rails-3.1.0')
    config.stubs(:evaluate).with('pwd', anything).returns('/path/to/current/directory')
    assert_equal '/path/to/current/directory/gemfiles/rails-3.1.0', config.gemfile
  end

  test 'gemfile? returns true if a Gemfile exists in the current working directory' do
    config = Config.new
    config.stubs(:gemfile).returns('/path/to/gemfile')
    config.stubs(:exec).with('test -f /path/to/gemfile', anything).returns(true)
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

