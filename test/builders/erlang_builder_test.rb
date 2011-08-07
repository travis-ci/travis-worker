require 'test_helper'

class BuilderErlangTest < Test::Unit::TestCase

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

  # tests for Travis::Worker::Builders::Erlang::Config

  def test_config_default_otp_release
    assert_equal('R14B02', new_config.otp_release)
  end

  def test_config_custom_otp_release
    config = new_config('otp_release' => 'foobar')
    assert_equal('foobar', config.otp_release)
  end

  def test_config_default_script
    assert_equal('rebar eunit', new_config.script)
  end

  def test_config_default_script_without_rebar
    config_any_instance.expects(:rebar?).once.returns(false)
    assert_equal('make test', new_config().script)
  end

  def test_config_default_rebar?
    assert_equal(true, new_config.rebar?)
  end

  def test_config_custom_rebar?
    config = new_config(:rebar => false)
    assert_equal(false, config.rebar?)
  end

  # tests for Travis::Worker::Builders::Erlang::Commands

  def test_setup_env
    commands_any_instance.expects(:exec).once.returns(true)
    new_commands.setup_env
  end

  def test_commands_install_dependencies_without_rebar
    new_commands(:rebar=>false).install_dependencies
  end

  def test_commands_install_dependencies_with_rebar
    commands_any_instance.expects(:exec).once.returns(true)
    new_commands(:rebar=>true).install_dependencies
  end

  def test_commands_install_property_without_rebar_and_without_rebar_config
    commands_any_instance.expects(:pwd).twice.returns('foobar')
    commands_any_instance.expects(:execute).twice.returns(false)

    assert !new_commands(:rebar => false).install?
  end

  def test_commands_install_property_with_rebar
    commands_any_instance.expects(:pwd).never
    commands_any_instance.expects(:execute).never

    assert new_commands(:rebar => true).install?
  end

  def test_commands_install_property_without_rebar_and_with_rebar_config
    commands_any_instance.expects(:pwd).once.returns('foobar')
    commands_any_instance.expects(:execute).once.returns(true)

    assert new_commands(:rebar => false).install?
  end
end
