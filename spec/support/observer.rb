class TestObserver
  attr_reader :events

  [:on_start, :on_update, :on_finish].each do |method|
    define_method(method) { |*args| (@events ||= []) << args }
  end
end
