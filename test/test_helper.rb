ENV['RAILS_ENV'] ||= 'test'

begin
  require 'ruby-debug'
rescue LoadError => e
  puts e.message
end
require 'bundler/setup'

require 'test/unit'
require 'test_declarative'
require 'mocha'
# require 'fakeredis'
# require 'resque'

require 'travis_worker'
require 'fixtures/payloads'
require 'test_helper/mocks'

class Test::Unit::TestCase
  attr_reader :shell

  def setup
    @shell = Travis::Worker.shell = Object.new
    Mocha::Mockery.instance.verify
  end

  def expect_shell(commands)
    commands.each do |command|
      shell.expects(:execute).with(command).returns(true)
    end
  end

  def within_em_loop
    EM.run do
      sleep(0.01) until EM.reactor_running?
      yield
      EM.stop
    end
  end
end

