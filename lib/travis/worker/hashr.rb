module Travis
  module Worker
    class Hashr < Hash
      module EnvDefaults
        def defaults
          deep_enverize(super)
        end

        protected

          def deep_enverize(hash, nesting = ['WORKER'])
            hash.each do |key, value|
              nesting << key.to_s.upcase
              hash[key] = case value
              when Hash
                deep_enverize(value, nesting)
              else
                ENV.fetch(nesting.join('_'), value)
              end.tap { nesting.pop }
            end
          end
      end

      TEMPLATE = new

      class << self
        def default(defaults)
          @defaults = defaults
        end

        def defaults
          @defaults ||= {}
        end
      end

      def initialize(data = {})
        replace(deep_hasherize(deep_merge(self.class.defaults, data)))
      end

      def []=(key, value)
        super(key, value.is_a?(Hash) ? self.class.new(value) : value)
      end

      def respond_to?(name)
        true
      end

      def method_missing(name, *args, &block)
        case name.to_s[-1]
        when '?'
          !!self[name.to_s[0..-2].to_sym]
        when '='
          self[name.to_s[0..-2].to_sym] = args.first
        else
          self[name]
        end
      end

      protected

        def deep_merge(left, right)
          merger = proc { |key, v1, v2| v1.is_a?(Hash) && v2.is_a?(Hash) ? self.class.new(v1.merge(v2, &merger)) : v2 }
          left.merge(right || {}, &merger)
        end

        def deep_hasherize(hash)
          hash.inject(TEMPLATE.dup) do |result, (key, value)|
            result.merge(key.to_sym => value.is_a?(Hash) ? deep_hasherize(value) : value)
          end
        end
    end
  end
end
