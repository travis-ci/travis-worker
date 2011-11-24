require 'travis/worker'
require 'travis/build'
require 'faraday'

module ConstantLoadHelper
  def load_constants(loaded = [])
    constants.each do |name|
      next if loaded.include?(name)
      loaded << name
      const = const_get(name)
      if const.is_a?(Class) || const.is_a?(Module)
        const.extend(ConstantLoadHelper)
        const.load_constants(loaded)
      end
    end
  end
end

targets = [Travis::Worker, Travis::Build, Faraday]

targets.each do |target|
  target.extend(ConstantLoadHelper)
  target.load_constants
end
