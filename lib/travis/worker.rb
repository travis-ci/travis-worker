require 'travis/worker/config'

module Travis
  module Worker
    class BuildStallTimeoutError < StandardError; end

    class << self
      def config
        @config ||= Config.new
      end
    end
  end
end
