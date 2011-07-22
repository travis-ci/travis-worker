# TODO use rubygems once travis-worker is a gem
$: << 'lib'
require 'travis/worker'
require 'fileutils'

config = Travis::Worker.config
root   = File.expand_path('.')
logs   = "#{root}/log"

FileUtils.mkdir_p(logs)

God.log_level = :info
God.log_file  = "#{logs}/god.log"

1.upto(config.vms.count) do |num|
  God.watch do |w|
    w.group    = 'workers'
    w.name     = "worker-#{num}"
    w.log      = "#{logs}/worker-#{num}.log"
    w.env      = { 'QUEUE' => config.queue, 'TRAVIS_ENV' => config.env, 'VM' => "worker-#{num}", 'VERBOSE' => 'true', 'PIDFILE' => File.expand_path("~/.god/pids/#{w.name}.pid") }
    w.start    = "cd #{root}; bundle exec rake resque:work --trace"
    w.interval = 30.seconds

    # determine the state on startup
    w.transition(:init, { true => :up, false => :start }) do |on|
      on.condition(:process_running) do |c|
        c.running = true
      end
    end

    # determine when process has finished starting
    w.transition([:start, :restart], :up) do |on|
      on.condition(:process_running) do |c|
        c.running = true
        c.interval = 5.seconds
      end

      # failsafe
      on.condition(:tries) do |c|
        c.times = 5
        c.transition = :start
        c.interval = 5.seconds
      end
    end

    # start if process is not running
    w.transition(:up, :start) do |on|
      on.condition(:process_running) do |c|
        c.running = false
      end
    end
  end
end

