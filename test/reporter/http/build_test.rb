require 'test_helper'

class ReporterHttpBuildTest < Test::Unit::TestCase
  include Travis

  attr_reader :job, :reporter, :now

  def setup
    super

    Worker::Config.any_instance.stubs(:load).returns({})

    @job = Job::Build.new(Hashie::Mash.new(INCOMING_PAYLOADS['build:gem-release']))
    class << job
      def build!
        update(:log => 'log')
        true
      end
    end

    @reporter = Reporter::Http.new(job.build)
    job.observers << reporter

    @now = Time.now
    Time.stubs(:now).returns(now)
  end

  test 'queues a :start message' do
    job.work!
    message = reporter.messages[0]
    assert_equal :start, message.type
    assert_equal '/builds/1', message.target
    assert_equal({ :_method => :put, :msg_id => 0, :build => { :started_at => now } }, message.data)
  end

  test 'queues a :log message' do
    job.work!
    message = reporter.messages[1]
    assert_equal :update, message.type
    assert_equal '/builds/1/log', message.target
    assert_equal({ :_method => :put, :msg_id => 1, :build => { :log => 'log' } }, message.data)
  end

  test 'queues a :finished message' do
    job.work!
    message = reporter.messages[3]
    assert_equal :finish, message.type
    assert_equal '/builds/1', message.target
    assert_equal({ :_method => :put, :msg_id => 3, :build => { :finished_at => now, :status => 0, :log => "log\nDone. Build script exited with: 0\n" } }, message.data)
  end
end


