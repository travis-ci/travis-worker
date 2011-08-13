require 'test_helper'

class JobHelpersRepositoryTest < Test::Unit::TestCase
  include Travis::Worker::Job

  Helpers::Repository.__send__ :public, *Helpers::Repository.protected_instance_methods(false)

  attr_reader :repository

  def setup
    super
    Helpers::Repository.any_instance.stubs(:exec)
    @repository = Helpers::Repository.new('svenfuchs/gem-release')
  end

  test 'checkout: clones a repository if the build dir is not a git repository' do
    repository.stubs(:exists?).returns(false)
    repository.expects(:clone)
    repository.checkout
  end

  test 'checkout: fetches a repository if the build dir is a git repository' do
    repository.stubs(:exists?).returns(true)
    repository.expects(:fetch)
    repository.checkout
  end

  test 'clone: clones the repository to the current directory' do
    repository.expects(:exec).with('export GIT_ASKPASS=echo', :echo => false)
    repository.expects(:exec).with('git clone --depth=1000 --quiet git://github.com/svenfuchs/gem-release.git svenfuchs/gem-release')
    repository.clone
  end

  test 'fetch: clones the repository to the current directory' do
    repository.expects(:exec).with('cd svenfuchs/gem-release', :echo => false).returns(true)
    repository.expects(:exec).with('git clean -fdx').returns(true)
    repository.expects(:exec).with('git fetch').returns(true)
    repository.fetch
  end

  test 'source: returns the read-only git url' do
    assert_equal 'git://github.com/svenfuchs/gem-release.git', repository.source
  end
end
