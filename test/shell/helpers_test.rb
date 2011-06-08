require 'test_helper'

class ShellTest < Test::Unit::TestCase
  include Travis::Shell::Helpers

  test 'echoize: echo the command before executing it (1)' do
    assert_equal "echo \\$\\ rake\nrake", echoize('rake')
  end

  test 'echoize: echo the command before executing it (2)' do
    assert_equal "echo \\$\\ rvm\\ use\\ 1.9.2\nrvm use 1.9.2\necho \\$\\ FOO\\=bar\\ rake\\ ci\nFOO=bar rake ci", echoize(['rvm use 1.9.2', 'FOO=bar rake ci'])
  end
end

