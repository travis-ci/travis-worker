require 'test_helper'

class JobBaseTest < Test::Unit::TestCase
  include Travis::Worker

  Job::Base.send :public, *Job::Base.protected_instance_methods(false)

  class TestObserver
    attr_reader :events

    [:on_start, :on_update, :on_finish].each do |method|
      define_method(method) { |*args| (@events ||= []) << args }
    end
  end

  test 'implements a simple observer pattern' do
    job = Job::Base.new({})
    observer = TestObserver.new
    job.observers << observer

    job.notify(:start,  :started)
    job.notify(:update, :data)
    job.notify(:finish, :finished)

    assert_equal [[:started], [:data], [:finished]], observer.events
  end

  # TODO which is wrong, but quickest way to fix this right now, Job::Repository.build_branch? assumes this
  # this stuff will probably be moved to the server/app
  test 'repository.config contains both the branch and branches configuration' do
    payload = { 'build' => { 'branch' => 'master', 'config' => { 'branches' => { 'only' => ['master'] } } }, 'repository' => { 'slug' => 'slug' } }
    config = Job::Base.new(payload).repository.config
    assert config.is_a?(Hashr)
    assert_equal 'master', config.branch
    assert_equal ['master'], config.branches.only
  end
end

