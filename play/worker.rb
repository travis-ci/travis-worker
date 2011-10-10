require 'rubygems'
require 'travis/worker'
require 'spec/support/payloads'

ENV['VM'] = 'worker-1'

payload = INCOMING_PAYLOADS['build:gem-release']
Travis::Worker.perform(payload)

