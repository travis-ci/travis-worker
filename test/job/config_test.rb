require 'test_helper'

class JobConfigTest < Test::Unit::TestCase
  include Travis::Worker

  Job::Config.send :public, *Job::Config.protected_instance_methods

  attr_reader :config, :shell

  def setup
    super
    @config = Job::Config.new(INCOMING_PAYLOADS['config:gem-release'])
  end

  def stub_github_request(response)
    Faraday::Connection.any_instance.
      stubs(:get).
      with('https://raw.github.com/svenfuchs/gem-release/313f61b/.travis.yml').
      returns(response)
  end

  test 'perform: reads and sets config' do
    # this works ...
    stub_github_request(Faraday::Response.new(:body => "---\n  script: rake ci", :status => 200))


    # this doesn't ... hu?
    # Faraday.adapter(:test) do |stub|
    #   stub.get('/svenfuchs/gem-release/1234567/.travis.yml') {[ 200, {}, "---\\\\\\\\n  script: rake ci" ]}
    # end

    config.perform
    assert_equal({ 'script' => 'rake ci', '.configured' => true }, config.config)
  end

  test 'fetch: returns an empty hash for a missing .travis.yml file' do
    stub_github_request(Faraday::Response.new(:body => 'Github 404 page', :status => 404))

    config.perform
    assert_equal({ '.configured' => true }, config.config)
  end

  if RUBY_VERSION >= '1.9.2'
    test 'fetch: returns an empty hash for a broken .travis.yml file' do
      stub_github_request(Faraday::Response.new(:body => 'order: [:year, :month, :day]', :status => 200))

      config.perform
      assert_equal({'.configured' => true}, config.config)
    end
  end
end

