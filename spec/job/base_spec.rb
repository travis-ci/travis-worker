require 'spec_helper'

describe Travis::Worker::Job::Base do
  include Travis::Worker

  before(:each) do
    Job::Base.send :public, *Job::Base.protected_instance_methods(false)
  end

  let(:job){ job = Job::Base.new({}) }
  it 'implements a simple observer pattern' do
    observer = TestObserver.new
    job.observers << observer

    job.notify(:start,  :started)
    job.notify(:update, :data)
    job.notify(:finish, :finished)

    observer.events.should eql [[:started], [:data], [:finished]]
  end
end
