require 'test_helper'
require 'hashie'

class JobBuildTest < Test::Unit::TestCase
  include Travis::Worker

  Job::Build.send :public, *Job::Build.protected_instance_methods
  Job::Build.base_dir = '/tmp/travis/test'

  attr_reader :payload, :build

  def setup
    super

    Config.any_instance.stubs(:load).returns({})

    @payload = INCOMING_PAYLOADS['build:test-project-1']
    @build = Job::Build.new(payload)
    @build.repository.config.stubs(:gemfile?).returns(true)

    FileUtils.mkdir_p(build.build_dir)
  end

  def teardown
    super
    FileUtils.rm_rf(Job::Build.base_dir)
  end

  test 'perform: builds and sets status and log' do
    build.expects(:build!).returns(true)
    build.notify(:update, :log => 'log')
    build.perform

    assert_equal "log\nDone. Build script exited with: 0\n", build.log
    assert_equal 0, build.status
  end

  test 'does not perform build if the branch is ignored' do
    build.repository.expects(:build?).returns(false)
    build.expects(:build!).never
    build.perform
  end

  test 'build!: sets rvm, env vars, checks the repository out, installs the bundle and runs the scripts' do
    build.repository.config.stubs(:gemfile?).returns(true)
    build.repository.config.stubs(:gemfile).returns('/path/to/Gemfile.rails-3.1')

    expect_shell [
      'mkdir -p /tmp/travis/test/travis-ci/test-project-1; cd /tmp/travis/test/travis-ci/test-project-1',
      'rvm use 1.9.2',
      'export BUNDLE_GEMFILE=/path/to/Gemfile.rails-3.1',
      'export FOO=bar',
      'export BAR=baz',
      'test -d .git',
      'git clean -fdx',
      'git fetch',
      'git checkout -qf 1234567',
      'bundle install --path vendor/bundle bundler_arg=1',
      'bundle exec rake ci:before',
      'bundle exec rake',
      'bundle exec rake ci:after'
    ]
    build.build!
  end

  test 'build_dir: the path from the github url local to the base builds dir' do
    assert_equal '/tmp/travis/test/travis-ci/test-project-1', build.build_dir.to_s
  end

  test 'on_update: appends the log data' do
    build.notify(:update, :log => 'log and ')
    build.notify(:update, :log => 'more log')
    assert_equal 'log and more log', build.log
  end

  test 'run_scripts: iterates over keys and executes appropriate script' do
    build.expects(:exec).with('bundle exec rake ci:before', :timeout => 'before_script').returns(true)
    build.expects(:exec).with('bundle exec rake', :timeout => 'script').returns(true)
    build.expects(:exec).with('bundle exec rake ci:after', :timeout => 'after_script').returns(true)
    build.run_scripts
  end

  test 'run_scripts: returns as soon as a script fails' do
    build.expects(:exec).with('bundle exec rake ci:before', :timeout => 'before_script').returns(false)
    build.expects(:exec).with('bundle exec rake', :timeout => 'script').never
    build.expects(:exec).with('bundle exec rake ci:after', :timeout => 'after_script').never
    assert_equal false, build.run_scripts
  end

  test 'run_script when passed a String' do
    options = { :timeout => 'before_script' }
    build.expects(:exec).with('./before_script', options).returns(true)
    build.run_script('./before_script', options)
  end

  test 'run_script when passed a multiline String' do
    options = { :timeout => 'before_script' }
    build.expects(:exec).with('./before_script_1', options).returns(true)
    build.expects(:exec).with('./before_script_2', options).returns(true)
    build.run_script("./before_script_1\n./before_script_2", options)
  end

  test 'run_script when passed an Array' do
    options = { :timeout => 'before_script' }
    build.expects(:exec).with('./before_script_1', options).returns(true)
    build.expects(:exec).with('./before_script_2', options).returns(true)
    build.run_script(['./before_script_1', './before_script_2'], options)
  end

  test 'setup_env sets up the environment with the default rvm and multiple env vars' do
    build.config.stubs(:gemfile?)
    build.config.stubs(:rvm).returns(nil)
    build.config.stubs(:env).returns(['FOO=true', 'BAR=true'])

    expect_shell [
      'rvm use default',
      'export FOO=true',
      'export BAR=true'
    ]
    build.setup_env
  end

  test 'setup_env sets up the environment with 1.9.2, a Gemfile and an empty env var (which is skipped)' do
    build.config.stubs(:gemfile?).returns(true)
    build.config.stubs(:gemfile).returns('path/to/Gemfile')
    build.config.stubs(:rvm).returns('1.9.2')
    build.config.stubs(:env).returns('')

    expect_shell [
      'rvm use 1.9.2',
      'export BUNDLE_GEMFILE=path/to/Gemfile'
    ]
    build.setup_env
  end
end
