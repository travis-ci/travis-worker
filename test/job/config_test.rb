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
    response = Faraday::Response.new
    response.body = "---\n  script: rake ci"
    response.status = 200

    Faraday.stubs(:get).with('https://raw.github.com/svenfuchs/gem-release/313f61b/.travis.yml').returns(response)

    # this doesn't ... hu?
    # Faraday.adapter(:test) do |stub|
    #   stub.get('/svenfuchs/gem-release/1234567/.travis.yml') {[ 200, {}, "---\\\\\\\\n  script: rake ci" ]}
    # end

    config.perform
    assert_equal({ 'script' => 'rake ci', '.configured' => true }, config.config)
  end

  # test 'fetch: returns an empty hash for a missing .travis.yml file' do
  #   response = Faraday::Response.new
  #   response.body = 'Github 404 page'
  #   response.status = 404

  #   Faraday.stubs(:get).with('https://raw.github.com/svenfuchs/gem-release/313f61b/.travis.yml').returns(response)

  #   config.perform
  #   assert_equal({}, config.config)
  # end

  test 'fetch: returns an empty hash for a broken .travis.yml file' do
    response = Faraday::Response.new
    response.body = 'order: [:year, :month, :day]'
    response.status = 200

    Faraday.stubs(:get).with('https://raw.github.com/svenfuchs/gem-release/313f61b/.travis.yml').returns(response)

    config.perform
    assert_equal({'.configured' => true}, config.config)
  end
end

