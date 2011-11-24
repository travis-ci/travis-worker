require 'spec_helper'

describe Worker::Reporter do
  let(:reporter) { Worker::Reporter.new(exchange) }
  let(:exchange) { stub('exchange', :publish => nil) }
  let(:event)    { stub('event', :name => 'build:started', :data => { :foo => :bar } ) }
  let(:logger)   { stub('logger', :before => nil, :after => nil) }
  let(:io)       { StringIO.new }

  before :each do
    Travis.logger = Logger.new(io)
  end

  describe 'notify' do
    it "publishes the given event's data with the given event's type" do
      exchange.expects(:publish).with({ :foo => :bar }, :properties => { :type => 'build:started' })
      reporter.notify(event)
    end
  end

  describe 'logging' do
    it 'logs before :message is being called' do
      reporter.notify(event)
      io.string.should include('about to message')
    end
  end
end

