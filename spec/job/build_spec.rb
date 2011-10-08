# require 'spec_helper'
# require 'vagrant'
#
# RSpec::Matchers.define :be_executed_by_shell do
#   match do |actual|
#     actual.each do |command|
#       Travis::Worker.shell.expects(:execute).with(command, anything).returns(true)
#     end
#   end
#
# end
#
# describe Travis::Worker::Job::Build do
#   include Travis::Worker
#
#   before(:each) do
#     Travis::Worker.shell = Mock::Shell.new
#
#     Config.any_instance.stubs(:read).returns({})
#     Job::Build.send :public, *Job::Build.protected_instance_methods
#     Job::Build.base_dir = '/tmp/travis/test'
#
#     ::Vagrant::Environment.new.stubs(:load!).returns({})
#     FileUtils.mkdir_p(build.build_dir)
#   end
#
#   after(:each) do
#     FileUtils.rm_rf(Job::Build.base_dir)
#   end
#
#   let(:payload) do
#     {
#       'repository' => {
#         'slug' => 'travis-ci/test-project-1',
#       },
#       'build' => {
#         'id' => 1,
#         'commit' => '1234567',
#         'config' => {
#           'rvm'           => '1.9.2',
#           'gemfile'       => 'Gemfile.rails-3.1',
#           'env'           => ['FOO=bar', 'BAR=baz'],
#           'before_script' => ['bundle exec rake ci:before'],
#           'after_script'  => ['bundle exec rake ci:after'],
#           'bundler_args'  => 'bundler_arg=1'
#         }
#       }
#     }
#   end
#
#   let(:build) {
#     build = Job::Build.new(payload)
#     build.repository.config.stubs(:gemfile?).returns(true)
#     build
#   }
#
#   describe :perform do
#     it 'builds and sets status and log' do
#       build.expects(:build!).returns(true)
#       build.notify(:update, :log => 'log')
#       build.perform
#
#       build.log.should eql "log\\nDone. Build script exited with: 0\\n"
#       build.status.should eql 0
#     end
#
#     it 'does not perform build if the branch is ignored' do
#       build.repository.expects(:build?).returns(false)
#       build.expects(:build!).never
#       build.perform
#     end
#   end
#
#   context :build do
#     let(:shell_commands) do
#       [
#         'mkdir -p /tmp/travis/test/travis-ci/test-project-1; cd /tmp/travis/test/travis-ci/test-project-1',
#         'rvm use 1.9.2',
#         'export BUNDLE_GEMFILE=/path/to/Gemfile.rails-3.1',
#         'export FOO=bar',
#         'export BAR=baz',
#         'test -d .git',
#         'git clean -fdx',
#         'git fetch',
#         'git checkout -qf 1234567',
#         'bundle install --path vendor/bundle bundler_arg=1',
#         'bundle exec rake ci:before',
#         'bundle exec rake',
#         'bundle exec rake ci:after'
#       ]
#     end
#
#
#     it 'build!: sets rvm, env vars, checks the repository out, installs the bundle and runs the scripts' do
#       build.repository.config.stubs(:gemfile?).returns(true)
#       build.repository.config.stubs(:gemfile).returns('/path/to/Gemfile.rails-3.1')
#
#       shell_commands.should be_executed_by_shell
#
#       build.build!
#     end
#   end
#
#   context :setup_env do
#     it 'setup_env sets up the environment with the default rvm and multiple env vars' do
#       build.config.stubs(:gemfile?)
#       build.config.stubs(:rvm).returns(nil)
#       build.config.stubs(:env).returns(['FOO=true', 'BAR=true'])
#
#       [
#         'rvm use default',
#         'export FOO=true',
#         'export BAR=true'
#       ].should be_executed_by_shell
#       build.setup_env
#     end
#
#     it 'setup_env sets up the environment with 1.9.2, a Gemfile and an empty env var (which is skipped)' do
#       build.config.stubs(:gemfile?).returns(true)
#       build.config.stubs(:gemfile).returns('path/to/Gemfile')
#       build.config.stubs(:rvm).returns('1.9.2')
#       build.config.stubs(:env).returns('')
#
#       [
#         'rvm use 1.9.2',
#         'export BUNDLE_GEMFILE=path/to/Gemfile'
#       ].should be_executed_by_shell
#
#       build.setup_env
#     end
#   end
# end
#
#
#
