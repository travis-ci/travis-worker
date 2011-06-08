module Travis
  module Reporter
    class Base
      # Queue is used to synchronize messages
      class Queue < Array
        Message = Struct.new(:type, :target, :data)

        attr_reader :msg_id

        def initialize
          @msg_id = 0
        end

        def add(type, target, data)
          # stdout.puts "\n----> #{type} ##{msg_id} to #{target}: #{data.inspect[0..80]}"
          self << Message.new(type, target, data.merge(:msg_id => @msg_id += 1))
        end

        def shift
          sort! { |lft, rgt| lft[0] <=> rgt[0] }
          # stdout.puts "\n<----    post #{first.type} ##{first.data[:msg_id]} to #{first.target}: #{first.data.inspect[0..80]}" unless empty?
          yield(first) unless empty?
          super
        end
      end
    end
  end
end
