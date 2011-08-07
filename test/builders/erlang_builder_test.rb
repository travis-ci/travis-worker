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

  def test_config_default_script
    assert_equal('make test', new_config.script)
  end

  def test_config_default_script_with_rebar
    config_any_instance.expects(:rebar?).once.returns(true)
    assert_equal('rebar eunit', new_config.script)
  end

  def test_config_default_script_without_rebar
    config_any_instance.expects(:rebar?).once.returns(false)
    assert_equal('make test', new_config.script)
  end

  def test_config_custom_script
    config = new_config(:script => 'make foo bar baz')
    assert_equal('make foo bar baz', config.script)
  end

  def test_config_default_rebar?
    assert_equal(false, new_config.rebar?)
  end

  def test_config_rebar_is_settable_and_changes_rebar?
    config = new_config
    assert_equal(false, config.rebar?)
    config.rebar = true
    assert_equal(true, config.rebar?)
  end

  def test_config_custom_rebar?
    config = new_config(:rebar => false)
    assert_equal(false, config.rebar?)
  end
end


class BuilderErlangCommandsTests < BuilderErlangTestCase
  def test_setup_env
    commands_any_instance.expects(:exec).
      with("source /home/vagrant/otp/R14B02/activate").
      once.returns(true)

    new_commands(:rebar => false).setup_env
  end

  def test_setup_env_with_other_env_vars
    commands_any_instance.expects(:exec).
      with("source /home/vagrant/otp/R14B02/activate").
      once.returns(true)

    commands_any_instance.expects(:exec).
      with("export FOO=bar").
      once.returns(true)

    new_commands(:env => "FOO=bar", :rebar => false).setup_env
  end

  def test_commands_install_dependencies_without_rebar
    commands_any_instance.expects(:pwd).twice.returns('/foo')
    commands_any_instance.expects(:execute).with("[ -f /foo/rebar.config ]").once.returns(false)
    commands_any_instance.expects(:execute).with("[ -f /foo/Rebar.config ]").once.returns(false)

    assert new_commands.install_dependencies
  end

  def test_commands_install_dependencies_without_rebar_set_by_config_var
    commands_any_instance.expects(:execute).never

    assert new_commands(:rebar => false).install_dependencies
  end

  def test_commands_install_dependencies_with_rebar_set_by_config_var
    commands_any_instance.expects(:execute).never
    commands_any_instance.expects(:exec).once.returns(true)

    assert new_commands(:rebar => true).install_dependencies
  end

  def test_commands_install_dependencies_with_rebar_file_check_true
    commands_any_instance.expects(:pwd).returns('/foo')
    commands_any_instance.expects(:execute).with("[ -f /foo/rebar.config ]").once.returns(true)
    commands_any_instance.expects(:exec).once.returns(true)

    assert new_commands.install_dependencies
  end
end


class BuilderErlangIntegrationTests < BuilderErlangTestCase
  def test_run_scripts_with_rebar_config_false
    commands_any_instance.expects(:exec).with('make test', :timeout => 'script').once.returns(true)

    assert new_commands('rebar' => false).run_scripts
  end

  def test_run_scripts_with_rebar_config_true
    commands_any_instance.expects(:exec).with('rebar eunit', :timeout => 'script').once.returns(true)

    assert new_commands('rebar' => true).run_scripts
  end

  def test_run_scripts_with_rebar_file_check_false
    commands_any_instance.expects(:pwd).twice.returns('/foo')
    commands_any_instance.expects(:execute).with("[ -f /foo/rebar.config ]").once.returns(false)
    commands_any_instance.expects(:execute).with("[ -f /foo/Rebar.config ]").once.returns(false)
    commands_any_instance.expects(:exec).with('make test', :timeout => 'script').once.returns(true)

    assert new_commands.run_scripts
  end

  def test_run_scripts_with_rebar_file_check_true
    commands_any_instance.expects(:pwd).returns('/foo')
    commands_any_instance.expects(:execute).with("[ -f /foo/rebar.config ]").once.returns(true)
    commands_any_instance.expects(:exec).with('rebar eunit', :timeout => 'script').once.returns(true)

    assert new_commands.run_scripts
  end
end
