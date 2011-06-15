require 'resque'

Resque::Job.class_eval do
  class << self
    def reserve_with_boxes(queue)
      return false unless vm = Travis::Worker.available_vms.shift
      reserve_without_boxes(queue).tap do |job|
        if job
          job.payload['args'].last.merge!(:vm => vm) if job
        else
          Travis::Worker.available_vms << vm
        end
      end
    end
    alias :reserve_without_boxes :reserve
    alias :reserve :reserve_with_boxes
  end

  def perform_with_boxes
    perform_without_boxes.tap do
      Travis::Worker.available_vms << this.vm
    end
  end
  alias :perform_without_boxes :perform
  alias :perform :perform_with_boxes
end
