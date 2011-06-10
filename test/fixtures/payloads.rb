# TODO should autogenerate these from the app

INCOMING_PAYLOADS = {
  'config:gem-release' => {
    'repository' => {
      'slug' => 'svenfuchs/gem-release'
    },
    'build' => {
      'id' => 1,
      'commit' => 'b0a1b69'
    }
  },
  'config:test-project-1' => {
    'repository' => {
      'slug' => 'travis-ci/test-project-1'
    },
    'build' => {
      'id' => 1,
      'commit' => '1234567'
    }
  },
  'build:gem-release' => {
    'repository' => {
      'slug' => 'svenfuchs/gem-release',
    },
    'build' => {
      'id' => 1,
      'commit' => 'b0a1b69',
      'config' => {
        'rvm'    => ["1.8.6", "1.8.7", "ree", "jruby"],
        'script' => 'ruby test/all.rb'
      }
    }
  },
  'build:test-project-1' => {
    'repository' => {
      'slug' => 'travis-ci/test-project-1',
    },
    'build' => {
      'id' => 1,
      'commit' => '1234567',
      'config' => {
        'rvm'           => '1.9.2',
        'gemfile'       => 'Gemfile.rails-3.1',
        'env'           => 'FOO=bar',
        'before_script' => ['bundle exec rake ci:before'],
        'after_script'  => ['bundle exec rake ci:after'],
        'bundler_args'  => 'bundler_arg=1'
      }
    }
  }
}

OUTGOING_PAYLOADS = {
  :started    => { 'build' => { 'started_at' => 'Mon Mar 07 01:42:00 +0100 2011' } },
  :configured => { 'build' => { 'config' => { 'script' => 'rake', 'rvm' => ['1.8.7', '1.9.2'], 'gemfile' => ['gemfiles/rails-2.3.x', 'gemfiles/rails-3.0.x'] } } },
  :log        => { 'build' => { 'log' => ' ... appended' } },
  :finished   => { 'build' => { 'finished_at' => 'Mon Mar 07 01:43:00 +0100 2011', 'status' => 1, 'log' => 'final build log' } }
}
