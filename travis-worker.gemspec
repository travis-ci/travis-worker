# encoding: utf-8

$:.unshift File.expand_path('../lib', __FILE__)
require 'travis/worker/version'

Gem::Specification.new do |s|
  s.name         = "travis-worker"
  s.version      = Travis::Worker::VERSION
  s.authors      = ["Sven Fuchs"]
  s.email        = "svenfuchs@artweb-design.de"
  s.homepage     = "http://github.com/svenfuchs/travis-worker"
  s.summary      = "[summary]"
  s.description  = "[description]"

  s.files        = Dir['{lib/**/*,test/**/*,[A-Z]*}']
  s.platform     = Gem::Platform::RUBY
  s.require_path = 'lib'
  s.rubyforge_project = '[none]'
end
