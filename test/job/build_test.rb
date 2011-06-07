require 'test_helper'
require 'hashie'

class JobBuildTest < Test::Unit::TestCase
  include Travis::Job

  Build.send :public, *Build.protected_instance_methods
  Build.base_dir = '/tmp/travis/test'

  attr_reader :payload, :build

  def setup
    super

    Build.any_instance.stubs(:puts) # silence output
    @payload = INCOMING_PAYLOADS['build:gem-release']
    @build = Build.new(payload)
    @build.repository.config.stubs(:gemfile?).returns(true)

    FileUtils.mkdir_p(build.build_dir)
  end

  def teardown
    super
    FileUtils.rm_rf(Build.base_dir)
  end

  test 'perform: changes to the build directory' do
    build.expects(:chdir)
    build.perform
  end

  test 'perform: builds and returns the result' do
    build.expects(:build!).returns(true)
    build.notify(:update, :log => 'log')
    assert_equal({ :log => 'log', :status => 0 }, build.perform)
  end

  test 'build!: sets rvm, env vars, checks the repository out, installs the bundle and runs the scripts' do
    build.repository.config.stubs(:gemfile?).returns(true)

    expect_shell [
      'rvm use 1.9.2',
      'BUNDLE_GEMFILE=Gemfile.rails-3.1',
      'FOO=bar',
      "git clone git://github.com/svenfuchs/gem-release.git #{build.build_dir.realpath}",
      'git checkout -qf 1234567',
      'bundle install bundler_arg=1',
      'bundle exec rake ci:before',
      'bundle exec rake',
      'bundle exec rake ci:after'
    ]
    build.build!
  end

  test 'build_dir: the path from the github url local to the base builds dir' do
    assert_equal '/tmp/travis/test/svenfuchs/gem-release', build.build_dir.to_s
  end

  test 'on_update: appends the log data' do
    build.notify(:update, :log => 'log and ')
    build.notify(:update, :log => 'more log')
    assert_equal 'log and more log', build.log
  end

  test 'run_scripts: iterates over keys and executes appropriate script' do
    build.expects(:exec).with('bundle exec rake ci:before').returns(true)
    build.expects(:exec).with('bundle exec rake').returns(true)
    build.expects(:exec).with('bundle exec rake ci:after').returns(true)
    build.run_scripts
  end

  test 'run_scripts: returns as soon as a script fails' do
    build.expects(:exec).with('bundle exec rake ci:before').returns(false)
    build.expects(:exec).with('bundle exec rake').never
    build.expects(:exec).with('bundle exec rake ci:after').never
    assert_equal false , build.run_scripts
  end
end
