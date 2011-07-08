require 'test_helper'

class JobConfigTest < Test::Unit::TestCase
  include Travis::Worker

  Job::Config.send :public, *Job::Config.protected_instance_methods

  attr_reader :config, :shell

  def setup
    super
    @config = Job::Config.new(INCOMING_PAYLOADS['config:gem-release'])
  end

  test 'perform: reads and sets config' do

    stubs_for_perform

    config.stubs(:`).with(backtick_command).returns("script: 'rake ci'")

    config.perform
    assert_equal({ 'script' => 'rake ci', '.configured' => true }, config.config)
  end

  test 'fetch: returns an empty hash for a missing .travis.yml file' do
    response = Faraday::Response.new(:body => 'Github 404 page', :status => 404)
    Faraday.stubs(:get).with('https://raw.github.com/svenfuchs/gem-release/313f61b/.travis.yml').returns(response)

    config.stubs(:`).with(backtick_command).returns("")

    config.perform
    assert_equal({ '.configured' => true }, config.config)
  end

  if RUBY_VERSION >= '1.9.2'
    test 'fetch: returns an empty hash for a broken .travis.yml file' do
      response = Faraday::Response.new(:body => 'order: [:year, :month, :day]', :status => 200)
      Faraday.stubs(:get).with('https://raw.github.com/svenfuchs/gem-release/313f61b/.travis.yml').returns(response)

      config.stubs(:`).with(backtick_command).returns("---\nscript: 'rak")

      config.perform
      assert_equal({'.configured' => true}, config.config)
    end
  end

  def stubs_for_perform
    Random.stubs(:rand).with(2000).returns(1)
    config.repository.stubs(:clone_url).returns("git://github.com/svenfuchs/gem-release.git")
  end

  def backtick_command
    "git clone --no-checkout --depth 1 --quiet git://github.com/svenfuchs/gem-release.git /tmp/travis-yml-1 && cd /tmp/travis-yml-1 && git show HEAD:.travis.yml && rm -rf /tmp/travis-yml-1"
  end
end

