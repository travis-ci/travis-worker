require 'spec_helper'
require 'travis/worker/utils/filtered_string'

describe Travis::Worker::Utils::FilteredString do
  it 'displays filtered string by default' do
    filtered   = 'FOO=[secure]'
    unfiltered = 'FOO=bar'

    str = Travis::Worker::Utils::FilteredString.new(unfiltered, filtered)
    expect(str.to_s).to   eq("FOO=[secure]")
    expect(str.to_str).to eq("FOO=[secure]")
  end

  it 'preserves filtered strings after split' do
    filtered   = "FOO=[secure]\nBAR=[secure]"
    unfiltered = "FOO=bar\nBAR=baz"

    str = Travis::Worker::Utils::FilteredString.new(unfiltered, filtered)
    array = str.split("\n")
    expect(array.map { |s| s.to_s       }).to eq(['FOO=[secure]', 'BAR=[secure]'])
    expect(array.map { |s| s.unfiltered }).to eq(['FOO=bar', 'BAR=baz'])
  end

  it 'raises an error if parts does not match after split' do
    filtered   = "FOO=[secure]\nBAR=[secure]"
    unfiltered = "FOO=bar"

    str = Travis::Worker::Utils::FilteredString.new(unfiltered, filtered)
    expect {
      array = str.split("\n")
    }.to raise_error(/can't split/)
  end
end
