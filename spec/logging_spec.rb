require 'spec_helper'
require 'stringio'

describe Logging do
  let :logging_class do
    Class.new do |c|
      c.extend(Logging)
      c.send(:attr_reader, :logger)
      c.send(:define_method, :initialize) { @logger = stub('logger', :log => nil) }
      c.send(:define_method, :the_method) { |*args| }
    end
  end

  let(:object) { logging_class.new }
  let(:logger) { object.logger }

  before :each do
    Logging.io = StringIO.new
  end

  describe 'without options' do
    before :each do
      logging_class.log :the_method
    end

    it 'logs before the call' do
      logger.expects(:log).with(:before, "Class", :the_method, [:args])
      object.the_method(:args)
    end

    it 'logs after the call' do
      logger.expects(:log).with(:after, "Class", :the_method)
      object.the_method(:args)
    end
  end

  describe 'given :only => :before' do
    before :each do
      logging_class.log :the_method, :only => :before
    end

    it 'logs before the call' do
      logger.expects(:log).with(:before, "Class", :the_method, [:args])
      object.the_method(:args)
    end

    it 'does not log after the call' do
      logger.expects(:log).with(:after, anything).never
      object.the_method(:args)
    end
  end

  describe 'given :only => :after' do
    before :each do
      logging_class.log :the_method, :only => :after
    end

    it 'does not log before the call' do
      logger.expects(:log).with(:before, anything).never
      object.the_method(:args)
    end

    it 'logs after the call' do
      logger.expects(:log).with(:after, "Class", :the_method)
      object.the_method(:args)
    end
  end
  
  describe 'given :params => false' do
    before :each do
      logging_class.log :the_method, :params => false
    end

    it 'does not log the params of the method call' do
      logger.expects(:log).with(:before, "Class", :the_method)
      object.the_method(:args)
    end
  end
end
