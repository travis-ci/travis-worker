require 'spec_helper'
require 'stringio'

describe Util::Logging do
  let :logging_class do
    Mock.const_set :LoggedClass, Class.new { |c|
      c.extend(Util::Logging)
      c.send(:attr_reader, :logger)
      c.send(:define_method, :initialize) { @logger = stub('logger', :log => nil) }
      c.send(:define_method, :the_method) { |*args| }
    }
  end

  let(:object) { logging_class.new }
  let(:logger) { object.logger }

  after :each do
    Mock.send(:remove_const, :LoggedClass)
  end

  describe 'without options' do
    before :each do
      logging_class.log :the_method
    end

    it 'logs before the call' do
      logger.expects(:log).with(:before, object, :the_method, [:args])
      object.the_method(:args)
    end

    it 'logs after the call' do
      logger.expects(:log).with(:after, object, :the_method)
      object.the_method(:args)
    end
  end

  describe 'given :only => :before' do
    before :each do
      logging_class.log :the_method, :only => :before
    end

    it 'logs before the call' do
      logger.expects(:log).with(:before, object, :the_method, [:args])
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
      logger.expects(:log).with(:after, object, :the_method)
      object.the_method(:args)
    end
  end

  describe 'arguments' do
    it 'logs arguments by default' do
      logging_class.log :the_method
      logger.expects(:log).with(:before, object, :the_method, [:args])
      object.the_method(:args)
    end

    it 'logs arguments when :params => true was given' do
      logging_class.log :the_method, :params => true
      logger.expects(:log).with(:before, object, :the_method, [:args])
      object.the_method(:args)
    end

    it 'does not log arguments when :params => false was given' do
      logging_class.log :the_method, :params => false
      logger.expects(:log).with(:before, object, :the_method)
      object.the_method(:args)
    end
  end
end
