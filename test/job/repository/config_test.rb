require 'test_helper'

class JobRepositoryConfigTest < Test::Unit::TestCase
  include Travis::Job

  Config = Repository::Config
  Config.send :public, *Config.protected_instance_methods(false)

  test 'gemfile? returns true if a Gemfile exists in the current working directory' do
    config = Config.new
    File.stubs(:exists?).returns(true)
    assert config.gemfile?
  end

  test 'script, before_script and after_script return the given :before_script and :after_script values' do
    config = Config.new(:script => 'script', :before_script => 'before script', :after_script => 'after script')
    assert_equal 'script', config.script
    assert_equal 'before script', config.before_script
    assert_equal 'after script', config.after_script
  end

  test 'script defaults to "bundle exec rake"' do
    config = Config.new
    assert_equal 'bundle exec rake', config.script
  end
end

