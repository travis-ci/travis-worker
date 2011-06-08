module Mocks
  class EmHttpRequest
    attr_accessor :requests

    def initialize(*args)
      @requests = []
    end

    def post(*args)
      requests << [:post, *args]
      EM.defer { @callback.call(self) if @callback }
      self
    end

    def callback(&block)
      @callback = block
    end

    def errback(&block)
      @errback = block
    end
  end
end
