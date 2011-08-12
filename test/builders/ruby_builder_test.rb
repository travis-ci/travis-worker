require 'test_helper'

class BuilderRubyTestCase < Test::Unit::TestCase
  def new_config(config={})
    Travis::Worker::Builders::Ruby::Config.new(config)
  end

  def config_any_instance
    Travis::Worker::Builders::Ruby::Config.any_instance
  end

  def new_commands(config={})
    Travis::Worker::Builders::Ruby::Commands.new(config)
  end

  def commands_any_instance
    Travis::Worker::Builders::Ruby::Commands.any_instance
  end
end

class BuilderRubyConfigTests < BuilderRubyTestCase
  def test_config_default_rvm
    assert_equal('default', new_config.rvm)
  end

  def test_config_custom_rvm
    config = new_config('rvm' => 'foobar')
    assert_equal('foobar', config.rvm)
  end

  def test_config_custom_rvm_as_an_array
    config = new_config('rvm' => ['foobar'])
    assert_equal('foobar', config.rvm)
  end

  def test_config_default_gemfile
    assert_equal('Gemfile', new_config.gemfile)
  end

  def test_config_custom_gemfile
    config = new_config('gemfile' => 'FooGemfile')
    assert_equal('FooGemfile', config.gemfile)
  end

  def test_config_custom_gemfile_as_an_array
    config = new_config('gemfile' => ['FooGemfile'])
    assert_equal('FooGemfile', config.gemfile)
  end

  def test_config_default_script_when_gemfile_does_not_exists
    assert_equal('rake', new_config.script)
  end

  def test_config_default_script_when_gemfile_exists
    assert_equal('bundle exec rake', new_config(:gemfile_exists => true).script)
  end

  def test_config_custom_script
    assert_equal('foo bar', new_config(:script => 'foo bar').script)
  end

  def test_gemfile_exsits_check_return_false_by_default
    assert !new_config.gemfile_exists?
  end
end


class BuilderRubyCommandsTests < BuilderRubyTestCase
  def test_setup_env
    commands_any_instance.expects(:exec).
      with("test -f Gemfile", :echo => false).
      once

    commands_any_instance.expects(:exec).
      with("rvm use default").
      once

    new_commands.setup_env
  end

  def test_setup_env_with_other_env_vars
    commands_any_instance.expects(:exec).
      with("test -f Gemfile", :echo => false).
      once

    commands_any_instance.expects(:exec).
      with("rvm use default").
      once

    commands_any_instance.expects(:exec).
      with("export FOO=bar").
      once.returns(true)

    new_commands(:env => "FOO=bar").setup_env
  end

  def test_setup_env_when_gemfile_exists
    commands_any_instance.expects(:exec).
      with("test -f Gemfile", :echo => false).
      once.returns(true)

    commands_any_instance.expects(:exec).
      with("rvm use default").
      once

    commands_any_instance.expects(:pwd).
      once.returns('/foo')

    commands_any_instance.expects(:exec).
      with("export BUNDLE_GEMFILE=/foo/Gemfile").
      once

    new_commands.setup_env
  end

  def test_commands_install_dependencies_without_gemfile
    commands_any_instance.expects(:exec).
      with("test -f Gemfile", :echo => false).
      once.returns(false)

    assert new_commands.install_dependencies
  end

  def test_commands_install_dependencies_with_gemfile_without_bundler_args
    commands_any_instance.expects(:exec).
      with("test -f Gemfile", :echo => false).
      once.returns(true)

    commands_any_instance.expects(:exec).
      with("bundle install", :timeout => :install_deps).
      once

    assert new_commands.install_dependencies
  end

  def test_commands_install_dependencies_with_gemfile_with_bundler_args
    commands_any_instance.expects(:exec).
      with("test -f Gemfile", :echo => false).
      once.returns(true)

    commands_any_instance.expects(:exec).
      with("bundle install --foobar", :timeout => :install_deps).
      once

    assert new_commands(:bundler_args => '--foobar').install_dependencies
  end
end
