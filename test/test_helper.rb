require 'simplecov'
SimpleCov.start

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

require 'travis/worker'
require 'test_helper/mock'

FIXTURES = {}
require 'fixtures/payloads'
require 'fixtures/vboxmanage'

class Test::Unit::TestCase
  attr_reader :shell

  def setup
    @shell = Travis::Worker.shell = Mock::Shell.new
    Mocha::Mockery.instance.verify
  end

  def expect_shell(commands)
    commands.each do |command|
      shell.expects(:execute).with(command, anything).returns(true)
    end
  end
end

