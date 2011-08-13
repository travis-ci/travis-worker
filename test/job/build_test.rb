require 'test_helper'

class JobBuildTest < Test::Unit::TestCase
  include Travis::Worker

  Job::Build.send :public, *Job::Build.protected_instance_methods
  Job::Build.base_dir = '/tmp/travis/test'

  attr_reader :payload, :build

  def setup
    super

    Config.any_instance.stubs(:read).returns({})

    @payload = INCOMING_PAYLOADS['build:test-project-1']
    @build = Job::Build.new(payload)
  end

  def teardown
    super
  end

  test 'perform: builds and sets status and log' do
    build.expects(:build!).returns(true)

    build.notify(:update, :log => 'log')

    build.perform

    assert_equal "log\nDone. Build script exited with: 0\n", build.log
    assert_equal 0, build.status
  end

  test 'build!: sets rvm, env vars, checks the repository out, installs the bundle and runs the scripts' do
    expect_shell [
      'mkdir -p /tmp/travis/test; cd /tmp/travis/test',
      'test -d travis-ci/test-project-1',
      'cd travis-ci/test-project-1',
      'git clean -fdx',
      'git fetch',
      'git checkout -qf 1234567',
      'test -f Gemfile.rails-3.1',
      'rvm use 1.9.2',
      { :command => 'pwd', :method => :evaluate, :returns => '/path/to' },
      'export BUNDLE_GEMFILE=/path/to/Gemfile.rails-3.1',
      'export FOO=bar',
      'export BAR=baz',
      'bundle install bundler_arg=1',
      'bundle exec rake ci:before',
      'bundle exec rake',
      'bundle exec rake ci:after'
    ]

    build.build!
  end

  test 'build!: sets rvm, env vars, clones the repository, installs the bundle and runs the scripts' do
    expect_shell [
      'mkdir -p /tmp/travis/test; cd /tmp/travis/test',
      { :command => 'test -d travis-ci/test-project-1', :method => :execute, :returns => false },
      'export GIT_ASKPASS=echo',
      'git clone --depth=1000 --quiet git://github.com/travis-ci/test-project-1.git travis-ci/test-project-1',
      'cd travis-ci/test-project-1',
      'git checkout -qf 1234567',
      'test -f Gemfile.rails-3.1',
      'rvm use 1.9.2',
      { :command => 'pwd', :method => :evaluate, :returns => '/path/to' },
      'export BUNDLE_GEMFILE=/path/to/Gemfile.rails-3.1',
      'export FOO=bar',
      'export BAR=baz',
      'bundle install bundler_arg=1',
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
end
