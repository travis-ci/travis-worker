require 'travis/worker/config'

module Travis
  module Worker

    class << self
      def config
        @config ||= Config.new
      end
    end

  end
end
