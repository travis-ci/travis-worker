require 'spec_helper'
require 'travis/worker/ssh/session'

describe Travis::Worker::Ssh::Session do
  describe '#exec' do
    it 'should stop the job if a block returns falsy value' do
      connector = stub(:connector)
      session  = described_class.new('test-session', connector: connector)

      session.expects(:buffer_flush_exceeded?).times(3)
      session.expects(:close).once
      connector.expects(:exec).with('./doit', session.send(:buffer)).
        multiple_yields([], [], [])

      i = 0
      session.exec("./doit") { i+=1; i == 3 ? false : true }
    end
  end
end
