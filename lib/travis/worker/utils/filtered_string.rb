module Travis
  module Worker
    module Utils
      class FilteredString < Struct.new(:unfiltered, :filtered)
        def to_s
          filtered
        end

        def to_str
          to_s
        end

        def mutate(*args)
          str = args.shift
          filtered = str % args
          unfiltered = str % args.map { |v| v.respond_to?(:unfiltered) ? v.unfiltered : v }

          FilteredString.new(unfiltered, filtered)
        end

        def split(*args)
          filtered_strings   = filtered.split(*args)
          unfiltered_strings = unfiltered.split(*args)

          if filtered_strings.length != unfiltered_strings.length
            raise "Splitted filtered and unfiltered strings do not match in length, can't split"
          end

          result = []
          filtered_strings.each_with_index do |f, i|
            result << FilteredString.new(unfiltered_strings[i], f)
          end
          result
        end
      end
    end
  end
end