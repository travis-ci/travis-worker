require 'spec_helper'

describe Travis::Worker::Shell::Helpers do
  let(:shell) do
    class Shell
      include Travis::Worker::Shell::Helpers
      attr_accessor :config
    end
    Shell.new
  end

  describe 'execute' do
    it "echoizes the command by default" do
      shell.stubs(:timeout).returns(0)
      shell.expects(:exec).with("echo \\$\\ ./super_command\n./super_command").returns(true)
      shell.execute('./super_command')
    end

    it "does not echoize if :echo => false" do
      shell.stubs(:timeout).returns(0)
      shell.expects(:exec).with("./super_command").returns(true)
      shell.execute('./super_command', :echo => false)
    end

    describe 'timeouts' do
      # TODO this test doesn't work for some reason :(
      #
      # it "raises a Travis::Build::CommandTimeout exception if the execution takes too long" do
      #   shell.expects(:timeout).with(:script).returns(1)
      #   shell.expects(:exec).with("./super_command").returns { sleep 2 }

      #   action = lambda do
      #     shell.execute('./super_command', :echo => false, :stage => :script)
      #   end
      #   action.should raise_error(Travis::Build::CommandTimeout)
      # end
    end
  end

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

    it 'echos obfuscated shell variables when secure' do
      shell.config = stub(:timeouts => {:default => 1})
      shell.expects(:exec).with(%(echo \\$\\ export\\ FOO\\=\\[secure\\]\\ TEST_WITH\\=\\[secure\\]\nexport FOO=bar TEST_WITH="ruby -I. test/ci"))
      shell.export_line('SECURE FOO=bar TEST_WITH="ruby -I. test/ci"')
    end

    it 'silently exports shell variables which start with TRAVIS_' do
      shell.expects(:execute).with('export TRAVIS_PULL_REQUEST=true', :echo => false)
      shell.export_line('TRAVIS_PULL_REQUEST=true')
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

  describe 'directory_exists?' do
    it 'looks for a directory using test -d' do
      shell.expects(:execute).with('test -d project', :echo => false)
      shell.directory_exists?('project')
    end
  end

  describe 'echoize' do
    it 'makes sure all commands to echo are to_s ified' do
      shell.echoize(true).should == "echo \\$\\ true\ntrue"
    end

    it 'works with multiple lines and array as argument' do
      expected = "echo \\$\\ foo\nfoo\n" +
                 "echo \\$\\ bar\nbar\n" +
                 "echo \\$\\ baz\nbaz\n" +
                 "echo \\$\\ qux\nqux"
      shell.echoize(["foo", "bar\nbaz", ["qux"]]).should == expected
    end

    it 'echo the command before executing it (1)' do
      shell.echoize('rake').should == "echo \\$\\ rake\nrake"
    end

    it 'echo the command before executing it (2)' do
      shell.echoize(['rvm use 1.9.2', 'FOO=bar rake ci']).should == "echo \\$\\ rvm\\ use\\ 1.9.2\nrvm use 1.9.2\necho \\$\\ FOO\\=bar\\ rake\\ ci\nFOO=bar rake ci"
    end

    it 'echo a modified command before executing the original (1)' do
      shell.echoize('rake') { |cmd| cmd.tr('ae', '43') }.should == "echo \\$\\ r4k3\nrake"
    end

    it 'echo a modified command before executing the original (2)' do
      shell.echoize(['rvm use 1.9.2', 'FOO=bar rake ci']) { |cmd| cmd.sub(/bar/, 'baz') }.should == "echo \\$\\ rvm\\ use\\ 1.9.2\nrvm use 1.9.2\necho \\$\\ FOO\\=baz\\ rake\\ ci\nFOO=bar rake ci"
    end
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
