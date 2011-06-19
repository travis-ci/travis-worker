require 'rubygems'
require 'travis/worker'

ENV['VM'] = 'worker-2'

if @child = fork
  Process.wait
else
  p Travis::Worker.vm.name
  p Travis::Worker.vm.ssh.port
  exit!
end


