require 'rubygems'
require 'travis/worker'
require 'fixtures/payloads'

payload = INCOMING_PAYLOADS['build:gem-release']
Travis::Worker.perform('12345', payload)

