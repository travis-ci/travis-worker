require 'test_helper'

class BuilderErlangTestCase < Test::Unit::TestCase
  def new_config(config={})
    Travis::Worker::Builders::Erlang::Config.new(config)
  end

  def config_any_instance
    Travis::Worker::Builders::Erlang::Config.any_instance
  end

  def new_commands(config={})
    Travis::Worker::Builders::Erlang::Commands.new(config)
  end

  def commands_any_instance
    Travis::Worker::Builders::Erlang::Commands.any_instance
  end
end

class BuilderErlangConfigTests < BuilderErlangTestCase
  def test_config_default_otp_release
    assert_equal('R14B02', new_config.otp_release)
  end

  def test_config_custom_otp_release
    config = new_config('otp_release' => 'foobar')
    assert_equal('foobar', config.otp_release)
  end

  def test_config_custom_otp_release_as_an_array
    config = new_config('otp_release' => ['foobar'])
    assert_equal('foobar', config.otp_release)
  end

  def test_config_default_script
    assert_equal('make test', new_config.script)
  end

  def test_config_default_script_with_rebar
    assert_equal('./rebar eunit', new_config(:rebar_config_exists => true).script)
  end

  def test_config_custom_script
    config = new_config(:script => 'make foo bar baz')
    assert_equal('make foo bar baz', config.script)
  end

  def test_config_default_rebar?
    assert_equal(false, new_config.rebar_config_exists?)
  end

  def test_config_rebar_is_settable_and_changes_rebar?
    config = new_config
    assert !config.rebar_config_exists?
    config.rebar_config_exists = true
    assert config.rebar_config_exists?
  end
end


class BuilderErlangCommandsTests < BuilderErlangTestCase
  def stub_rebar_check(exists = true)
    commands_any_instance.expects(:exec).
      with("test -f rebar.config", :echo => false).
      once.returns(exists)
  end

  def test_initialize
    stub_rebar_check

    new_commands
  end

  def test_setup_env
    stub_rebar_check

    commands_any_instance.expects(:exec).
      with("source /home/vagrant/otp/R14B02/activate").
      once.returns(true)

    new_commands.setup_env
  end

  def test_setup_env_with_other_env_vars
    stub_rebar_check

    commands_any_instance.expects(:exec).
      with("source /home/vagrant/otp/R14B02/activate").
      once.returns(true)

    commands_any_instance.expects(:exec).
      with("export FOO=bar").
      once.returns(true)

    new_commands(:env => "FOO=bar").setup_env
  end

  def test_commands_install_dependencies_without_rebar
    commands_any_instance.expects(:exec).
      with("test -f rebar.config", :echo => false).
      once.returns(false)

    commands_any_instance.expects(:exec).
      with("test -f Rebar.config", :echo => false).
      once.returns(false)

    assert new_commands.install_dependencies
  end

  def test_commands_install_dependencies_with_rebar
    commands_any_instance.expects(:exec).
      with("test -f rebar.config", :echo => false).
      once.returns(true)

    commands_any_instance.expects(:exec).
      with('./rebar get-deps', :timeout => :install_deps).
      once.returns(true)

    assert new_commands.install_dependencies
  end
end
