travis_env  = ENV['TRAVIS_ENV']  || "production"
travis_root = ENV['TRAVIS_ROOT'] || File.expand_path('..', __FILE__)

God.log_file  = "#{travis_root}/log/god.log"
God.log_level = :info

God.watch do |w|
  w.name     = "resque"
  w.log      = "#{travis_root}/log/resque.log"
  w.env      = { 'QUEUE' => 'builds', 'TRAVIS_ENV' => travis_env, 'VERBOSE' => 'true', 'PIDFILE' => "/home/travis/.god/pids/#{w.name}.pid" }
  w.start    = "cd #{travis_root}; rake resque:work --trace"
  w.interval = 30.seconds

  # w.uid = 'travis'
  # w.gid = 'travis'

  # retart if memory gets too high
  w.transition(:up, :restart) do |on|
    on.condition(:memory_usage) do |c|
      c.above = 350.megabytes
      c.times = 2
    end
  end

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

