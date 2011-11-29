require 'thor'
require 'thor/runner'
require 'readline'

class Thor
  class Console
    class << self
      def prompt
        @prompt ||= '>> '
      end

      def prompt=(prompt)
        @prompt = prompt
      end
    end

    include Readline

    attr_accessor :namespace

    def initialize(namespace = '')
      Thor::Runner.new.send(:initialize_thorfiles)

      Readline.completion_append_character = ' '
      Readline.completion_proc = lambda { |prefix| Travis::Worker.config.names.grep(/^#{Regexp.escape(prefix)}/).map { |n| "#{n} " } }

      @namespace = namespace
      run
    end

    protected

      def run
        loop do
          line = readline(prompt, true)
          break if line.nil?
          evaluate(line) unless line.empty?
        end
        puts
      end

      def prompt
        namespaced(self.class.prompt, ' ')
      end

      def gets
        begin
          $stdin.gets.chomp
        rescue NoMethodError, Interrupt
        end
      end

      def evaluate(line)
        args = parse(line)
        task = Thor.send(:retrieve_task_name, args)

        case task
        when namespaced('with')
          self.namespace = args.first
        when 'list'
          Thor::Runner.new.invoke(:list) # TODO lists wrong namespaces for commands
        else
          invoke(task, args)
        end
      end

      def invoke(task, args)
        config = { :shell => Thor::Base.shell.new }
        args, options = Thor::Options.split(args)
        klass, method = Thor::Util.find_class_and_task_by_namespace(task)

        if klass
          klass.new(args, options, config).invoke(method, args, options, config)
        else
          puts "unknown command"
        end
      end

      def parse(line)
        args = line.split(' ')
        args[0] = namespaced(args[0])
        args
      end

      def namespaced(token, delimiter = ':')
        [namespace, token].compact.join(delimiter)
      end
  end
end

