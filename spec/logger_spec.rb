require 'spec_helper'
require 'stringio'

describe Logger do
  let(:logger) { Logger.new('vm', StringIO.new) }
  let(:object) { Object.new }

  describe 'before' do
    it 'contains the log header' do
      logger.before(:the_method, [:foo, :bar])
      logger.io.string.should include('[vm]')
    end

    it 'contains the called method' do
      logger.before(:the_method, [:foo, :bar])
      logger.io.string.should include('about to the_method(:foo, :bar)')
    end

    it 'colorizes the output (yellow)' do
      logger.before(:the_method, [:foo, :bar])
      logger.io.string.should include("\e[33m")
    end
  end

  describe 'after' do
    it 'contains the log header' do
      logger.after(:the_method)
      logger.io.string.should include('[vm]')
    end

    it 'contains the called method' do
      logger.after(:the_method)
      logger.io.string.should include('done: the_method')
    end

    it 'colorizes the output (yellow)' do
      logger.after(:the_method)
      logger.io.string.should include("\e[33m")
    end
  end

  describe 'error' do
    let(:error) { stub('exception', :message => 'tis kaputt', :backtrace => ['kaputt.rb']) }

    it 'contains the log header' do
      logger.error(error)
      logger.io.string.should include('[vm]')
    end

    it 'contains the error class name' do
      logger.error(error)
      logger.io.string.should include('Mocha::Mock')
    end

    it 'contains the error message' do
      logger.error(error)
      logger.io.string.should include('Mocha::Mock: tis kaputt')
    end

    it 'contains the backtrace' do
      logger.error(error)
      logger.io.string.should include('kaputt.rb')
    end

    it 'colorizes the output (red)' do
      logger.error(error)
      logger.io.string.should include("\e[31m")
    end
  end
end
