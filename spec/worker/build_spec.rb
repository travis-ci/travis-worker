# require 'spec_helper'
# 
# describe Travis::Worker do
#   let(:requests) do
#     [
#       [:post, '/builds/1',     { :build => { :started_at => @now } }],
#       [:post, '/builds/1/log', { :build => { :log => "Using worker: the_worker\\n\\n" } }],
#       [:post, '/builds/1/log', { :build => { :log => 'log' } }],
#       [:post, '/builds/1/log', { :build => { :log => "\\nDone. Build script exited with: 0\\n" } }],
#       [:post, '/builds/1',     { :build => { :log => "Using worker: the_worker\\n\\nlog\\nDone. Build script exited with: 0\\n", :status => 0, :finished_at => @now } }],
#     ]
#   end
# 
#   let(:config) do
#     { 'test' => { 'reporter' => { 'http' => { 'url' => 'http://sven:1234567890@travis-ci.org' } } } }
#   end
# 
#   let(:worker) do
#     Travis::Worker::Workers::Resque.new(INCOMING_PAYLOADS['build:gem-release'])
#   end
#   let(:job) { worker.job }
#   let(:reporter) { worker.reporter }
# 
#   before :each do
#     @now = Time.now
#     Time.stubs(:now).returns(@now)
# 
#     Travis::Worker::Config.any_instance.stubs(:read).returns(config)
#     Travis::Worker.stubs(:name).returns('the_worker')
# 
#     Travis::Worker.shell = Mock::Shell.new
# 
#     class << reporter # stubbing doesn't seem to work in a separate thread?
#       def connection(*)
#         Mock::HttpRequest.new
#       end
#     end
#   end
# 
# 
#   it "should run a build" do
#     job.expects(:build!).with { job.send(:update, :log => 'log'); true }.returns(true)
#     worker.work!
# 
#     requests.each_with_index do |message, index|
#       message[2].merge!(:_method=>:put, :msg_id => index)
#       Mock::HttpRequest.requests[index].should eql message
#     end
#   end
# end
