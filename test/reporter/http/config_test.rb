require 'test_helper'

class ReporterHttpConfigTest < Test::Unit::TestCase
  include Travis::Worker

  attr_reader :job, :reporter, :now

  def setup
    super

    @job = Job::Config.new(Hashr.new(INCOMING_PAYLOADS['build:gem-release']))
    job.stubs(:fetch).returns('foo' => 'bar')

    @reporter = Reporter::Http.new(job.build)
    job.observers << reporter

    @now = Time.now
    Time.stubs(:now).returns(now)
  end

  test 'queues a :finished message' do
    job.work!
    message = reporter.messages[0]
    assert_equal :finish, message.type
    assert_equal '/builds/1', message.target
    assert_equal({ :_method => :put, :msg_id => 0, :build => { :config => { 'foo' => 'bar', '.configured' => true } } }, message.data)
  end
end



