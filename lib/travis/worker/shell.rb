module Travis
  module Worker
    module Shell

      #
      # Behaviors
      #

      autoload :Buffer,  'travis/worker/shell/buffer'
      autoload :Helpers, 'travis/worker/shell/helpers'
      autoload :Session, 'travis/worker/shell/session'

      #
      # API
      #

      # @see Travis::Shell::Session#execute
      def exec(*args)
        Travis::Worker::Worker.shell.execute(*args)
      end

      def evaluate(*args)
        Travis::Worker::Worker.shell.evaluate(*args)
      end

      def sandboxed(&block)
        Travis::Worker::Worker.shell.sandboxed(&block)
      end
    end # Shell
  end # Worker
end # Travis
