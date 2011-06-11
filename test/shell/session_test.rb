require 'test_helper'

class ShellSessionTest < Test::Unit::TestCase
  include Travis

  Shell::Session.send :public, *Shell::Session.protected_instance_methods

  attr_reader :session

  def setup
    super
    Shell::Session.any_instance.stubs(:start_shell)
    Shell::Session.any_instance.stubs(:start_sandbox)
    @session = Shell::Session.new(nil, nil)
  end

  test 'echoize: echo the command before executing it (1)' do
    assert_equal "echo \\$\\ rake\nrake", session.echoize('rake')
  end

  test 'echoize: echo the command before executing it (2)' do
    assert_equal "echo \\$\\ rvm\\ use\\ 1.9.2\nrvm use 1.9.2\necho \\$\\ FOO\\=bar\\ rake\\ ci\nFOO=bar rake ci", session.echoize(['rvm use 1.9.2', 'FOO=bar rake ci'])
  end
end

