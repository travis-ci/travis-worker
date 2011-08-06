require 'test_helper'
require 'hashr'

class BuilderBaseTest < Test::Unit::TestCase

  def new_builder(config = {})
    Travis::Worker::Builders::Base.new(config)
  end

  ## instantiation
  def test_new_sets_the_config
    builder = new_builder
    assert_equal({}, builder.config)
  end

  ## run
  def test_run_sets_up_the_env_and_install_dependencies_and_runs_scripts
    Travis::Worker::Builders::Base.any_instance.expects(:setup_env).once.returns(true)
    Travis::Worker::Builders::Base.any_instance.expects(:install_dependencies).once.returns(true)
    Travis::Worker::Builders::Base.any_instance.expects(:run_scripts).once.returns(true)
    new_builder.run
  end

  def test_run_sets_up_the_env_and_install_dependencies_only_if_install_dependencies_returns_false
    Travis::Worker::Builders::Base.any_instance.expects(:setup_env).once.returns(true)
    Travis::Worker::Builders::Base.any_instance.expects(:install_dependencies).once.returns(false)
    Travis::Worker::Builders::Base.any_instance.expects(:run_scripts).never
    new_builder.run
  end

  ## setup_env
  def test_setup_env_does_nothing_if_config_env_is_empty
    Travis::Worker::Builders::Base.any_instance.expects(:exec).never
    new_builder.setup_env
  end

  def test_setup_env_does_nothing_if_elements_in_config_env_are_empty
    Travis::Worker::Builders::Base.any_instance.expects(:exec).never
    new_builder(:env => ['', '']).setup_env
  end

  def test_setup_envs_accepts_a_string_config_env
    Travis::Worker::Builders::Base.any_instance.expects(:exec).once.returns(true)
    new_builder(:env => "FOO=BAR").setup_env
  end

  def test_setup_env_accepts_an_array_config_env
    Travis::Worker::Builders::Base.any_instance.expects(:exec).once.returns(true)
    new_builder(:env => ["FOO=bar"]).setup_env
  end

  def test_setup_env_accepts_an_array_config_env_with_more_than_one_item
    Travis::Worker::Builders::Base.any_instance.expects(:exec).twice.returns(true)
    new_builder(:env => ["FOO=bar", "BAR=BAZ"]).setup_env
  end

  ## install_dependencies
  def test_install_dependencies_does_nothing_and_returns_true_by_default
    assert new_builder.install_dependencies
  end

  ## run_scripts
  def test_run_scripts_calls_run_script_with_before_script_script_and_after_script
    assert false
  end
end