require 'test_helper'

class JobRepositoryTest < Test::Unit::TestCase
  include Travis::Job

  Repository.send :public, *Repository.protected_instance_methods(false)

  attr_reader :repository

  def setup
    super
    Repository.any_instance.stubs(:exec)
    Dir.stubs(:pwd).returns('/current/directory')
    @repository = Repository.new('https://github.com/travis-ci/test-project-1', {})
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
    repository.expects(:exec).with('git clone git://github.com/travis-ci/test-project-1.git /current/directory')
    repository.clone
  end

  test 'fetch: clones the repository to the current directory' do
    repository.expects(:exec).with('git clean -fdx')
    repository.expects(:exec).with('git fetch')
    repository.fetch
  end

  test 'source: returns the read-only git url' do
    assert_equal 'git://github.com/travis-ci/test-project-1.git', repository.source
  end

  test 'path: returns the path from the github url' do
    assert_equal '/travis-ci/test-project-1', repository.path
  end
end
