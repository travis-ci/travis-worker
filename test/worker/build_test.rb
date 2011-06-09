require 'test_helper'

STDOUT.sync = true

class WorkerBuildTest < Test::Unit::TestCase
  include Travis

  attr_reader :now, :shell, :worker, :job, :reporter

  def setup
    super
    Worker.config.reporter.http.url = 'http://sven:1234567890@travis-ci.org'

    @now = Time.now
    Time.stubs(:now).returns(now)

    Travis::Worker.shell = Mock::Shell.new

    @worker   = Worker.new('meta_id', INCOMING_PAYLOADS['build:gem-release'])
    @job      = worker.job
    @reporter = worker.reporter

    class << reporter # stubbing doesn't seem to work in a separate thread?
      def http(*)
        Mock::HttpRequest.new
      end
    end
  end

  test 'running a build' do
    job.expects(:build!).with { job.send(:update, :log => 'log'); true }.returns(true)
    worker.work!

    assert_messages [
      { :build => { :started_at => now } },
      { :build => { :log => 'log' } },
      { :build => { :log => "\nDone. Build script exited with: 0\n" } },
      { :build => { :log => "log\nDone. Build script exited with: 0\n", :status => 0, :finished_at => now } },
    ]
  end

  protected

    def assert_messages(messages)
      messages.each_with_index do |data, i|
        actual   = Mock::HttpRequest.requests[i]
        expected = [:post, { :body => data.merge(:_method => :put, :msg_id => i + 1), :head => { 'authorization' => ['sven', '1234567890'] } }]
        assert_equal expected, actual
      end
    end
end
