require 'test_helper'
require 'hashr'

class BuilderBaseTest < Test::Unit::TestCase

  def new_builder(config = {})
    Travis::Worker::Builders::Base::Commands.new(config)
  end

  def builder_any_instance
    Travis::Worker::Builders::Base::Commands.any_instance
  end

  ## instantiation
  def test_new_sets_the_config
    builder = new_builder
    assert_equal({}, builder.config)
  end

  ## run
  def test_run_sets_up_the_env_and_install_dependencies_and_runs_scripts
    builder_any_instance.expects(:setup_env).once.returns(true)
    builder_any_instance.expects(:run_install_dependencies).once.returns(true)
    builder_any_instance.expects(:run_scripts).once.returns(true)

    new_builder.run
  end

  def test_run_sets_up_the_env_and_install_dependencies_only_if_install_dependencies_returns_false
    builder_any_instance.expects(:setup_env).once.returns(true)
    builder_any_instance.expects(:run_install_dependencies).once.returns(false)
    builder_any_instance.expects(:run_scripts).never

    new_builder.run
  end

  ## setup_env
  def test_setup_env_does_nothing_if_config_env_is_empty
    builder_any_instance.expects(:exec).never

    new_builder.setup_env
  end

  def test_setup_env_does_nothing_if_elements_in_config_env_are_empty
    builder_any_instance.expects(:exec).never

    new_builder(:env => ['', '']).setup_env
  end

  def test_setup_envs_accepts_a_string_config_env
    builder_any_instance.expects(:exec).once.returns(true)

    new_builder(:env => "FOO=BAR").setup_env
  end

  def test_setup_env_accepts_an_array_config_env
    builder_any_instance.expects(:exec).once.returns(true)

    new_builder(:env => ["FOO=bar"]).setup_env
  end

  def test_setup_env_accepts_an_array_config_env_with_more_than_one_item
    builder_any_instance.expects(:exec).twice.returns(true)

    new_builder(:env => ["FOO=bar", "BAR=BAZ"]).setup_env
  end

  ## install_dependencies
  def test_run_install_dependencies_does_nothing_and_returns_true_by_default
    builder_any_instance.expects(:run_command).never

    assert new_builder.run_install_dependencies
  end

  def test_run_install_dependencies_calls_run_command_with_before_install_command_if_defined_in_config
    builder_any_instance.expects(:run_command).with('foo', :timeout => :before_install).once.returns(true)

    assert new_builder(:before_install => 'foo').run_install_dependencies
  end

  def test_run_install_dependencies_calls_run_command_with_install_command_if_defined_in_config
    builder_any_instance.expects(:run_command).with('foo', :timeout => :install).once.returns(true)

    assert new_builder(:install => 'foo').run_install_dependencies
  end

  def test_run_install_dependencies_calls_run_command_with_after_install_command_if_defined_in_config
    builder_any_instance.expects(:run_command).with('foo', :timeout => :after_install).once.returns(true)

    assert new_builder(:after_install => 'foo').run_install_dependencies
  end

  def test_run_install_dependencies_calls_run_command_with_before_install_and_install_dependencies_if_defined_in_config
    builder_any_instance.expects(:run_command).with('foo', :timeout => :before_install).once.returns(true)
    builder_any_instance.expects(:run_command).with('bar', :timeout => :install).once.returns(true)

    assert new_builder(:before_install => 'foo', :install => 'bar').run_install_dependencies
  end

  def test_run_install_dependencies_calls_run_command_with_before_install_install_and_after_install_if_defined_in_config
    builder_any_instance.expects(:run_command).with('foo', :timeout => :before_install).once.returns(true)
    builder_any_instance.expects(:run_command).with('bar', :timeout => :install).once.returns(true)
    builder_any_instance.expects(:run_command).with('baz', :timeout => :after_install).once.returns(true)

    assert new_builder({
      :before_install => 'foo',
      :install => 'bar',
      :after_install => 'baz'
    }).run_install_dependencies
  end

  def test_run_install_dependencies_does_not_call_run_command_with_install_if_before_install_fails
    builder_any_instance.expects(:run_command).with('foo', :timeout => :before_install).once.returns(false)
    builder_any_instance.expects(:run_command).with('bar', :timeout => :install).never

    assert !new_builder(:before_install => 'foo', :install => 'bar').run_install_dependencies
  end

  ## run_scripts
  def test_run_scripts_calls_does_not_call_run_command_if_config_does_not_define_any_scripts
    builder_any_instance.expects(:run_command).never

    assert new_builder.run_scripts
  end

  def test_run_scripts_calls_call_run_command_script_if_defined_in_config
    builder_any_instance.expects(:run_command).with('foo', :timeout => :script).once.returns(true)

    assert new_builder(:script => 'foo').run_scripts
  end

  def test_run_scripts_calls_call_run_command_before_script_and_script_if_defined_in_config
    builder_any_instance.expects(:run_command).with('foo', :timeout => :before_script).once.returns(true)
    builder_any_instance.expects(:run_command).with('bar', :timeout => :script).once.returns(true)

    assert new_builder(:before_script => 'foo', :script => 'bar').run_scripts
  end

  def test_run_scripts_calls_call_run_command_before_script_and_script_and_after_script_if_defined_in_config
    builder_any_instance.expects(:run_command).with('foo', :timeout => :before_script).once.returns(true)
    builder_any_instance.expects(:run_command).with('bar', :timeout => :script).once.returns(true)
    builder_any_instance.expects(:run_command).with('baz', :timeout => :after_script).once.returns(true)

    assert new_builder(:before_script => 'foo', :script => 'bar', :after_script => 'baz').run_scripts
  end

  def test_run_scripts_does_not_call_script_if_before_script_fails
    builder_any_instance.expects(:run_command).with('foo', :timeout => :before_script).once.returns(false)
    builder_any_instance.expects(:run_command).with('bar', :timeout => :script).never

    assert !new_builder(:before_script => 'foo', :script => 'bar').run_scripts
  end

  ## run_script
  def test_run_command_does_not_call_exec_if_script_is_an_empty_array
    builder_any_instance.expects(:exec).never

    assert new_builder.run_command([])
  end

  def test_run_command_calls_exec_once_if_script_is_a_string
    builder_any_instance.expects(:exec).with('foo', {}).once.returns(true)

    assert new_builder.run_command('foo')
  end

  def test_run_command_calls_exec_twice_if_script_is_an_array_with_two_items
    builder_any_instance.expects(:exec).with('foo', {}).once.returns(true)
    builder_any_instance.expects(:exec).with('bar', {}).once.returns(true)

    assert new_builder.run_command(['foo', 'bar'])
  end

  def test_run_command_calls_exec_once_if_script_is_an_array_and_the_first_script_fails
    builder_any_instance.expects(:exec).with('foo', {}).once.returns(false)
    builder_any_instance.expects(:exec).with('bar', {}).never

    assert !new_builder.run_command(['foo', 'bar'])
  end

  def test_run_command_calls_exec_and_passes_options_through
    builder_any_instance.expects(:exec).with('foo', { :bar => 'baz' }).once.returns(true)

    assert new_builder.run_command('foo', :bar => 'baz')
  end
end