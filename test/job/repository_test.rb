require 'test_helper'

class JobRepositoryTest < Test::Unit::TestCase
  include Travis::Worker::Job

  Repository.__send__ :public, *Repository.protected_instance_methods(false)

  attr_reader :repository

  def setup
    super
    Repository.any_instance.stubs(:exec)
    @repository = Repository.new('/path/to/build/dir', 'svenfuchs/gem-release', {})
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
    repository.expects(:exec).with('mkdir -p /path/to/build/dir', :echo => false)
    repository.expects(:exec).with('git clone --depth=1000 --quiet git://github.com/svenfuchs/gem-release.git /path/to/build/dir')
    repository.clone
  end

  test 'fetch: clones the repository to the current directory' do
    repository.expects(:exec).with('git clean -fdx')
    repository.expects(:exec).with('git fetch')
    repository.fetch
  end

  test 'source: returns the read-only git url' do
    assert_equal 'git://github.com/svenfuchs/gem-release.git', repository.source
  end
end
