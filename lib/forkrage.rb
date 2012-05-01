# Process handler for the analyzer
# Can fork the process into the background if 'daemonize' option is true
# Runs the analyzer loop
# Can be stopped by sending the signals TERM, INT or QUIT, handles the currently running job and then exits

require 'yaml'
require 'logger'
require 'fileutils'

class Forkrage
  attr_accessor :worker
  attr_writer :config

  def self.run(name="default", &blk)
    new(name).run(&blk)
  end

  def initialize(name="default")
    @name = name
  end

  def run(&blk)
    if ARGV[0] == "stop"
      stop
      return
    end

    check_pid_file
    @worker = blk.call
    daemonize if config['daemonize']
    write_pid_file
    setup_logger(config)
    setup_signal_handlers
    run_worker 
  end

  def stop
    if File.exists?(pid_file)
      pid = File.read(pid_file).strip.to_i
      begin
        Process.kill(:TERM, pid)
      rescue Errno::ESRCH
        puts "Didn't find a running process for #{@name} with pid #{pid}"
      ensure
        FileUtils.rm_f(pid_file)
      end
    end
  end

  def config
    @config ||= begin
      YAML.load(File.read(File.dirname(__FILE__) + "/../config/daemon.yml"))
    rescue
      puts $!
      {} 
    end
  end

  def daemonize
    exit if pid = fork
    Process.setsid
    exit if pid = fork

    File.umask 0000

    STDIN.reopen '/dev/null'
    STDOUT.reopen "log/#{@name}.out.log", 'a'
    STDERR.reopen STDOUT
  end

  def check_pid_file
    if File.exists?(pid_file)
      pid = File.read(pid_file).to_i
      begin
        Process.kill(0, File.read(pid_file).to_i)
        raise "Process with pid #{pid} is still running."
      rescue Errno::ESRCH
      end
    end
  end

  def write_pid_file
    File.open(pid_file, "w") do |f|
      f.write($$)
    end
  end

  def setup_signal_handlers
    [:INT, :QUIT, :TERM].each do |signal|
      trap signal do
        handle_shutdown
      end
    end
  end

  def setup_logger(config)
    config['logger'] = if config['daemonize']
      logger = Logger.new("log/#{@name}.log", 'weekly')
      logger.level = Logger::INFO 
      logger
    else
      Logger.new(STDOUT)
    end
  end

  def handle_shutdown
    begin
      worker.stop
    rescue Exception => e
    end
  ensure
    remove_pid_file
  end

  def pid_file
    @pid_file ||= "#{config['pid_dir']}/#{@name}.pid"
  end

  def remove_pid_file
    File.delete(pid_file)
  end

  def run_worker
    worker.run(config)
  end
end
