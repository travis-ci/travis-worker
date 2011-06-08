require 'test_helper'

STDOUT.sync = true

class WorkerTest < Test::Unit::TestCase
  include Travis

  attr_reader :now, :shell, :worker, :http

  def setup
    super
    @now = Time.now
    Time.stubs(:now).returns(now)

    @shell = Travis::Worker.shell = Object.new
    shell.expects(:execute).never

    @http = Mocks::EmHttpRequest.new
    Reporter::Http.any_instance.stubs(:http).returns(http)

    Job::Build.any_instance.stubs(:puts) # silence output

    Worker.config.reporter.http.url = 'http://sven:1234567890@travis-ci.org'
  end

  def receive(payload)
    @worker = Worker.new('meta_id', INCOMING_PAYLOADS['build:gem-release'])
  end

  def job
    worker.job
  end

  def reporter
    worker.reporter
  end

  test 'running a build' do
    within_em_loop do
      receive(INCOMING_PAYLOADS['build:gem-release'])
      job.expects(:build!).with { puts 'log'; true }.returns(true)
      worker.work!

      sleep(1)
      requests = reporter.http.requests
      head = { 'authorization' => ['sven', '1234567890'] }

      job.stdout.puts requests.inspect
      job.stdout.puts job.buffer.inspect

      assert_equal [:post, { :body => { :_method => :put, :msg_id => 1, :build => { :started_at => now } }, :head => head }], requests[0]
      assert_equal [:post, { :body => { :_method => :put, :msg_id => 2, :build => { :log => 'log' } }, :head => head }], requests[1]
      assert_equal [:post, { :body => { :_method => :put, :msg_id => 3, :build => { :finished_at => now, :log => 'log', :status => 0 } }, :head => head }], requests[2]
    end
  end
end
