require 'thor'
require 'thor/console'
require 'travis/worker'

module Travis
  module Worker
    module Cli
      class Console < Thor
        namespace 'travis'

        desc 'console', 'Start the Travis console'
        method_option :with,  :aliases => '-w', :type => :string, :default => 'travis:worker', :desc => 'Initial command namespace'
        def console
          Thor::Console.new(options['with'])
        end
      end
    end
  end
end


