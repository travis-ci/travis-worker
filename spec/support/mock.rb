module Mock
  class VM
    attr_reader :name
  end

  class Shell
    attr_reader :on_output

    def sandboxed
      yield
    end

    def output(data)
      on_output.call(self, data) if on_output
    end

    def on_output=(&block)
      @on_output = block
    end

    def close
    end
  end

  class HttpRequest
    class << self
      def requests
        @requests ||= []
      end
    end

    def post(*args)
      self.class.requests << [:post, *args]
      self
    end

    def success?
      true
    end
  end
end
