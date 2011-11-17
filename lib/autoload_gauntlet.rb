require 'travis/worker'
require 'travis/build'
require 'faraday'

module AutoloadHelper
  def load_autoloaded_constants(recursive = false)
    constants.each do |name|
      next unless autoload?(name)
      const = const_get(name)
      if recursive
        const.extend(AutoloadHelper)
        const.load_autoloaded_constants(true)
      end
    end
  end
end

targets = [Travis::Worker, Travis::Build, Faraday]

targets.each do |target|
  target.extend(AutoloadHelper)
  target.load_autoloaded_constants(true)
end
