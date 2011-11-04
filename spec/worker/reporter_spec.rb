require 'spec_helper'

describe Worker::Reporter do
  let(:reporter) { Worker::Reporter.new(exchange, logger) }
  let(:exchange) { stub('exchange', :publish => nil) }
  let(:event)    { stub('event', :name => 'build:started', :data => { :foo => :bar } ) }
  let(:logger)   { stub('logger', :before => nil, :after => nil) }

  describe 'notify' do
    it "publishes the given event's data with the given event's type" do
      exchange.expects(:publish).with({ :foo => :bar }, :properties => { :type => 'build:started' })
      reporter.notify(event)
    end
  end

  describe 'logging' do
    it 'logs before :message is being called' do
      logger.expects(:before).with(:message, ["build:started", {:foo=>:bar}])
      reporter.notify(event)
    end
  end
end

