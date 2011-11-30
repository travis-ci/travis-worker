require 'spec_helper'

describe Travis::Worker::Reporter do
  let(:reporter) { Travis::Worker::Reporter.new('staging-1', jobs, workers) }
  let(:jobs)     { stub('jobs', :publish => nil) }
  let(:workers)  { stub('workers', :publish => nil) }
  let(:logger)   { stub('logger', :before => nil, :after => nil) }
  let(:io)       { StringIO.new }

  before :each do
    Travis.logger = Logger.new(io)
  end

  describe 'notify' do
    it "publishes the a message for 'build:started' to the jobs exchange" do
      jobs.expects(:publish).with({ :foo => :bar }, :properties => { :type => 'build:started' })
      reporter.notify('build:started', :foo => :bar)
    end

    it "publishes the a message for 'job:started' to the jobs exchange" do
      jobs.expects(:publish).with({ :foo => :bar }, :properties => { :type => 'job:started' })
      reporter.notify('job:started', :foo => :bar)
    end

    it "publishes the a message for 'worker:started' to the workers exchange" do
      workers.expects(:publish).with({ :foo => :bar }, :properties => { :type => 'worker:started' })
      reporter.notify('worker:started', :foo => :bar)
    end
  end

  describe 'logging' do
    it 'logs before :message is being called' do
      reporter.notify('build:started', :foo => :bar)
      io.string.should include('about to message')
    end
  end
end
