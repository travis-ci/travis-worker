# From https://github.com/celluloid/celluloid/issues/26#issuecomment-4968921
require 'celluloid'

RSpec.configuration.before(:each) do
  class Celluloid::ActorProxy
    unless @rspec_compatible
      @rspec_compatible = true
      if respond_to?(:should_receive)
        undef_method :should_receive
      end
    end
  end
end
