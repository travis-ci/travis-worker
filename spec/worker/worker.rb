require 'spec_helper'

class FakeVirtualMachine
  def prepare

  end
end

describe Travis::Worker::Worker do
  let(:payload) do
    {
      'repository' => {
        'slug' => 'svenfuchs/gem-release',
      },
      'build' => {
        'id' => 1,
        'commit' => '313f61b',
        'branch' => 'master',
        'config' => {
          'rvm'    => '1.8.7',
          'script' => 'rake'
        }
      }
    }
  end

  let(:config) do
    { 'test' => { 'reporter' => { 'http' => { 'url' => 'http://sven:1234567890@travis-ci.org' } } } }
  end

  it "subscribes to jobs que and starts job processing when payload is received" do
    Travis::Worker::Config.any_instance.stubs(:read).returns(config)
    Travis::Worker::VirtualMachine::VirtualBox.stubs(:new).returns(FakeVirtualMachine.new)

    connection = HotBunnies.connect
    channel = connection.create_channel
    channel.prefetch = 1
    exchange = channel.exchange('', :type => :direct, :durable => true)
    jobs_queue = channel.queue('builds', :durable => true, :exculsive => false)
    reporting_queue = channel.queue('reporting.jobs', :durable => true, :exculsive => false)

    Travis::Worker::Worker.any_instance.expects(:process_job).once
    Travis::Worker::Worker.new("name", jobs_queue, reporting_queue).run
    exchange.publish("", :routing_key => 'builds')
    sleep 2
  end
end
