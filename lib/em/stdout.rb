require 'eventmachine'

module EventMachine
  class << self
    attr_accessor :stdout

    def split_stdout
      self.stdout, read, write = STDOUT.clone, *IO.pipe
      EM.attach(read, Stdout) do |connection|
        yield connection if block_given?
      end
      STDOUT.reopen(write)
    end

    def reset_stdout
      STDOUT.reopen($_stdout)
    end
  end

  class Stdout < EventMachine::Connection
    class << self
      def output
        defined?(@@output) ? @@output : @@output = true
      end

      def output=(output)
        @@output = output
      end
    end

    def callback(&block)
      @callback = block
    end

    def on_close(&block)
      @on_close = block
    end

    def receive_data(data)
      EM.stdout.print(data) if self.class.output
      @callback.call(data) if @callback
    end

    def unbind
      STDOUT.reopen(EM.stdout)
      @on_close.call if @on_close
    end
  end
end

