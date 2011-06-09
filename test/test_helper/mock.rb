module Mock
  class Shell
    attr_reader :on_output

    def output(data)
      on_output.call(self, data) if on_output
    end

    def on_output=(&block)
      @on_output = block
    end
  end

  class HttpRequest
    class << self
      def requests
        @requests ||= []
      end
    end

    attr_accessor :requests

    def post(*args)
      self.class.requests << [:post, *args]
      self
    end

    def callback(&block)
      yield(self)
    end

    def errback(&block)
      @errback = block
    end
  end
end
