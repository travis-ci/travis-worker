require 'eventmachine'

module EventMachine
  class << self
    attr_accessor :stdout

    def split_stdout
      EM.defer do
        self.stdout = STDOUT.clone
        read, write = *IO.pipe
        EM.attach(read, Stdout) do |connection|
          connection.stdout = stdout
          yield connection if block_given?
        end
        STDOUT.reopen(write)
      end
      sleep(0.01) until stdout
      stdout
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

    attr_accessor :stdout

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
      STDOUT.reopen(stdout)
      @on_close.call if @on_close
    end
  end
end

