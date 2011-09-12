require 'test_helper'

class BuilderNodeJsTestCase < Test::Unit::TestCase
  def new_config(config={})
    Travis::Worker::Builders::NodeJs::Config.new(config)
  end

  def config_any_instance
    Travis::Worker::Builders::NodeJs::Config.any_instance
  end

  def new_commands(config={})
    Travis::Worker::Builders::NodeJs::Commands.new(config)
  end

  def commands_any_instance
    Travis::Worker::Builders::NodeJs::Commands.any_instance
  end
end

class BuilderNodeJsConfigTests < BuilderNodeJsTestCase
  def test_config_default_nodejs_version
    assert_equal('0.4.11', new_config.nodejs_version)
  end

  def test_config_custom_nodejs_version
    config = new_config('nodejs' => 'foobar')
    assert_equal('foobar', config.nodejs_version)
  end

  def test_config_custom_nodejs_version_as_an_array
    config = new_config('nodejs' => ['foobar'])
    assert_equal('foobar', config.nodejs_version)
  end

  def test_config_default_script_when_package_does_not_exist
    assert_equal('make test', new_config.script)
  end

  def test_config_default_script_when_package_exists
    assert_equal('npm test', new_config(:package_exists => true).script)
  end

  def test_config_custom_script
    assert_equal('foo bar', new_config(:script => 'foo bar').script)
  end

  def test_pacakge_exist_check_return_false_by_default
    assert !new_config.package_exists?
  end
end


class BuilderNodeJsCommandsTests < BuilderNodeJsTestCase
  def test_setup_env
    commands_any_instance.expects(:exec).
      with("test -f package.json", :echo => false).
      once

    commands_any_instance.expects(:exec).
      with("nvm use v0.4.11").
      once

    new_commands.setup_env
  end

  def test_setup_env_with_other_env_vars
    commands_any_instance.expects(:exec).
      with("test -f package.json", :echo => false).
      once

    commands_any_instance.expects(:exec).
      with("nvm use v0.4.11").
      once

    commands_any_instance.expects(:exec).
      with("export FOO=bar").
      once.returns(true)

    new_commands(:env => "FOO=bar").setup_env
  end

  def test_setup_env_when_package_exists
    commands_any_instance.expects(:exec).
      with("test -f package.json", :echo => false).
      once.returns(true)

    commands_any_instance.expects(:exec).
      with("nvm use v0.4.11").
      once
    new_commands.setup_env
  end

  def test_commands_install_dependencies_without_package
    commands_any_instance.expects(:exec).
      with("test -f package.json", :echo => false).
      once.returns(false)

    assert new_commands.install_dependencies
  end

  def test_commands_install_dependencies_with_package_without_npm_args
    commands_any_instance.expects(:exec).
      with("test -f package.json", :echo => false).
      once.returns(true)

    commands_any_instance.expects(:exec).
      with("npm install", :timeout => :install_deps).
      once

    assert new_commands.install_dependencies
  end

  def test_commands_install_dependencies_with_package_with_npm_args
    commands_any_instance.expects(:exec).
      with("test -f package.json", :echo => false).
      once.returns(true)

    commands_any_instance.expects(:exec).
      with("npm install --foobar", :timeout => :install_deps).
      once

    assert new_commands(:npm_args => '--foobar').install_dependencies
  end
end
