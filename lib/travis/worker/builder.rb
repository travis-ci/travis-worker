require 'hashr'

module Travis
  module Worker
    module Builder

      class << self
        def create(config)
          lang = camelize(config.language || Travis::Worker.config.default_language || 'ruby')
          case lang
          when "Node.js", "Nodejs"
            Travis::Worker::Builder::NodeJs
          else
            args = [lang]
            args << false if Kernel.method(:const_get).arity == -1
            Travis::Worker::Builder.const_get(*args)
          end
        end

        private
          def camelize(lower_case_and_underscored_word)
            lower_case_and_underscored_word.to_s.gsub(/\/(.?)/) { "::#{$1.upcase}" }.gsub(/(?:^|_)(.)/) { $1.upcase }
          end
      end

      autoload :Base,     'travis/worker/builder/base'
      autoload :Clojure,  'travis/worker/builder/clojure'
      autoload :Erlang,   'travis/worker/builder/erlang'
      autoload :Ruby,     'travis/worker/builder/ruby'
      autoload :NodeJs,   'travis/worker/builder/node_js'
    end
  end
end
