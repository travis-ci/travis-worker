require 'rubygems'
require 'travis/worker'
require 'fixtures/payloads'

payload = INCOMING_PAYLOADS['build:gem-release']

Travis::Worker.class_eval { @queue = 'builds' }

2.times do
  Resque.enqueue(Travis::Worker, payload)
end

