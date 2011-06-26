module Travis
  module Worker
    module Reporter
      class Base
        # Queue is used to synchronize messages
        class Queue < Array
          Message = Struct.new(:type, :target, :data)

          attr_reader :msg_id

          def initialize
            @msg_id = -1
          end

          def add(type, target, data)
            # puts "\n----> #{type} ##{msg_id} to #{target}: #{data.inspect[0..80]}"
            self << Message.new(type, target, data.merge(:msg_id => @msg_id += 1))
            sort! { |lft, rgt| lft.data[:msg_id] <=> rgt.data[:msg_id] }
          end

          def shift
            # puts "\n<----    post #{first.type} ##{first.data[:msg_id]} to #{first.target}: #{first.data.inspect[0..80]}" unless empty?
            yield(first) unless empty?
            super
          end
        end # Queue
      end # Base
    end # Reporter
  end # Worker
end # Travis
