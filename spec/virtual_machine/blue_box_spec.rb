require 'spec_helper'
require 'travis/worker/virtual_machine/blue_box'

Fog.mock!

describe Travis::Worker::VirtualMachine::BlueBox do
  it 'is true' do
    expect(true).to be_truthy
  end
end