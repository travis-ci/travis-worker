require 'hashr'
require 'multi_json'

module Travis
  module Serialization
    def encode(data)
      MultiJson.encode(data)
    end

    def decode(data)
      MultiJson.decode(data)
    end
  end
end
