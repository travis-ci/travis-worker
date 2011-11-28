require 'spec_helper'

describe Shell::Helpers do
  let(:shell) { Class.new { include Shell::Helpers }.new }

  describe 'export' do
    it 'exports a shell variable (no options given)' do
      shell.expects(:execute).with('export FOO=bar')
      shell.export('FOO', 'bar')
    end

    it 'exports a shell variable (options given)' do
      shell.expects(:execute).with('export FOO=bar', :echo => true)
      shell.export('FOO', 'bar', :echo => true)
    end
  end

  describe 'export_line' do
    it 'exports a shell variable (no options given)' do
      shell.expects(:execute).with('export TEST_WITH="ruby -I. test/ci"')
      shell.export_line('TEST_WITH="ruby -I. test/ci"')
    end

    it 'exports multiple shell variable (options given)' do
      shell.expects(:execute).with('export FOO=bar TEST_WITH="ruby -I. test/ci"', :echo => true)
      shell.export_line('FOO=bar TEST_WITH="ruby -I. test/ci"', :echo => true)
    end
  end

  describe 'chdir' do
    before(:each) { shell.stubs(:execute) }

    it 'silently creates the target directory using mkdir -p' do
      shell.expects(:execute).with('mkdir -p ~/builds', :echo => false)
      shell.chdir('~/builds')
    end

    it 'cds into that directory' do
      shell.expects(:execute).with('cd ~/builds')
      shell.chdir('~/builds')
    end
  end

  describe 'cwd' do
    it 'evaluates the current directory using pwd' do
      shell.expects(:evaluate).with('pwd').returns("/home/vagrant/builds\n")
      shell.cwd.should == "/home/vagrant/builds"
    end
  end

  describe 'file_exists?' do
    it 'looks for a file using test -f' do
      shell.expects(:execute).with('test -f Gemfile', :echo => false)
      shell.file_exists?('Gemfile')
    end
  end

  describe 'echoize' do
    it 'echo the command before executing it (1)' do
      shell.echoize('rake').should == "echo \\$\\ rake\nrake"
    end

    it 'echo the command before executing it (2)' do
      shell.echoize(['rvm use 1.9.2', 'FOO=bar rake ci']).should == "echo \\$\\ rvm\\ use\\ 1.9.2\nrvm use 1.9.2\necho \\$\\ FOO\\=bar\\ rake\\ ci\nFOO=bar rake ci"
    end

    it 'removes a prefix from the echo command' do
      shell.echoize('timetrap -t 900 rake').should == "echo \\$\\ rake\ntimetrap -t 900 rake"
    end
  end

  describe 'timetrap' do
    it 'wraps a command without env vars into a command without a timeout' do
      shell.timetrap('rake').should == 'timetrap rake'
    end

    it 'wraps a command without env vars into a command with a timeout' do
      shell.timetrap('rake', :timeout => 900).should == 'timetrap -t 900 rake'
    end

    it 'wraps a command with env vars into a command without a timeout' do
      shell.timetrap('FOO=bar rake').should == 'FOO=bar timetrap rake'
    end

    it 'wraps a command with env vars into a command with a timeout' do
      shell.timetrap('FOO=bar rake', :timeout => 900).should == 'FOO=bar timetrap -t 900 rake'
    end

    # This breaks scripts that contain SQL statements with a ;, e.g. 'mysql -e "create database foo;"'.
    # Would need a more sophisticated parser :/
    #
    # it 'wraps multiple commands with env vars into a command with a timeout' do
    #   shell.timetrap('FOO=bar rake ci:prepare; rake', :timeout => 900) 'FOO=bar timetrap -t 900 rake ci:prepare; -t 900 rake'
    # end
  end

  describe 'parse_cmd' do
    it 'given a command that contains env vars it returns an array containing env vars and the command' do
      shell.parse_cmd('FOO=bar rake').should == ['FOO=bar', 'rake']
    end

    it 'given a command that contains not env vars it returns an array containing nil and the command' do
      shell.parse_cmd('rake').should == [nil, 'rake']
    end
  end
end
