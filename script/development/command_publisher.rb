#!/usr/bin/env ruby

$: << 'lib'
require 'travis/worker/cli/development'
require 'thor/runner'

Travis::Worker::Development::Job.start
