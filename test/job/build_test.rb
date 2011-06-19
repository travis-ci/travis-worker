require 'test_helper'
require 'hashie'

class JobBuildTest < Test::Unit::TestCase
  include Travis

  Job::Build.send :public, *Job::Build.protected_instance_methods
  Job::Build.base_dir = '/tmp/travis/test'

  attr_reader :payload, :build

  def setup
    super

    Worker::Config.any_instance.stubs(:load).returns({})

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

  test 'build!: sets rvm, env vars, checks the repository out, installs the bundle and runs the scripts' do
    build.repository.config.stubs(:gemfile?).returns(true)

    expect_shell [
      'mkdir -p /tmp/travis/test/travis-ci/test-project-1; cd /tmp/travis/test/travis-ci/test-project-1',
      'rvm use 1.9.2',
      'export BUNDLE_GEMFILE=Gemfile.rails-3.1',
      'export FOO=bar',
      'export BAR=baz',
      'test -d .git',
      'git clean -fdx',
      'git fetch',
      'git checkout -qf 1234567',
      'bundle install bundler_arg=1',
      'bundle exec rake ci:before 2>&1',
      'bundle exec rake 2>&1',
      'bundle exec rake ci:after 2>&1'
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
    build.expects(:exec).with('bundle exec rake ci:before 2>&1').returns(true)
    build.expects(:exec).with('bundle exec rake 2>&1').returns(true)
    build.expects(:exec).with('bundle exec rake ci:after 2>&1').returns(true)
    build.run_scripts
  end

  test 'run_scripts: returns as soon as a script fails' do
    build.expects(:exec).with('bundle exec rake ci:before 2>&1').returns(false)
    build.expects(:exec).with('bundle exec rake 2>&1').never
    build.expects(:exec).with('bundle exec rake ci:after 2>&1').never
    assert_equal false , build.run_scripts
  end
end
