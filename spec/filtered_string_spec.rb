require 'spec_helper'
require 'filtered_string'

describe FilteredString do
  it 'displays filtered string by default' do
    filtered   = 'FOO=[secure]'
    unfiltered = 'FOO=bar'

    str = FilteredString.new(unfiltered, filtered)
    str.to_s.should   == "FOO=[secure]"
    str.to_str.should == "FOO=[secure]"
  end

  it 'preserves filtered strings after split' do
    filtered   = "FOO=[secure]\nBAR=[secure]"
    unfiltered = "FOO=bar\nBAR=baz"

    str = FilteredString.new(unfiltered, filtered)
    array = str.split("\n")
    array.map { |s| s.to_s       }.should == ['FOO=[secure]', 'BAR=[secure]']
    array.map { |s| s.unfiltered }.should == ['FOO=bar', 'BAR=baz']
  end

  it 'raises an error if parts does not match after split' do
    filtered   = "FOO=[secure]\nBAR=[secure]"
    unfiltered = "FOO=bar"

    str = FilteredString.new(unfiltered, filtered)
    expect {
      array = str.split("\n")
    }.to raise_error(/can't split/)
  end
end
