require 'test_helper'

class JobConfigTest < Test::Unit::TestCase
  include Travis

  Job::Config.send :public, *Job::Config.protected_instance_methods

  attr_reader :config, :shell

  def setup
    super
    @config = Job::Config.new(INCOMING_PAYLOADS['config:gem-release'])
  end

  test 'perform: reads and sets config' do
    # this works ...
    response = Faraday::Response.new.tap { |r| r.body = "---\n  script: rake ci" }
    Faraday.stubs(:get).with('https://raw.github.com/svenfuchs/gem-release/1234567/.travis.yml').returns(response)

    # this doesn't ... hu?
    # Faraday.adapter(:test) do |stub|
    #   stub.get('/svenfuchs/gem-release/1234567/.travis.yml') {[ 200, {}, "---\\\\\\\\n  script: rake ci" ]}
    # end

    config.perform
    assert_equal({ 'script' => 'rake ci' }, config.config)
  end
end

