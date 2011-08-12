require 'hashr'

module Travis
  module Worker
    module Builders

      class << self
        def builder_for(config)
          lang = camelize(config.language || Travis::Worker.config.default_language || 'ruby')
          args = [lang]
          args << false if Kernel.method(:const_get).arity == -1
          Travis::Worker::Builders.const_get(*args)
        end

        private
          def camelize(lower_case_and_underscored_word)
            lower_case_and_underscored_word.to_s.gsub(/\/(.?)/) { "::#{$1.upcase}" }.gsub(/(?:^|_)(.)/) { $1.upcase }
          end
      end

      autoload :Base,     'travis/worker/builders/base'
      autoload :Clojure,  'travis/worker/builders/clojure'
      autoload :Erlang,   'travis/worker/builders/erlang'
      autoload :Ruby,     'travis/worker/builders/ruby'
    end
  end
end