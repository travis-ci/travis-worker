require 'jruby'
require 'timeout'

module SafeTimeout
  def self.timeout(sec, klass=nil)
    return yield(sec) if sec == nil or sec.zero?
    thread = Thread.new { yield(sec) }

    if thread.join(sec).nil?
      java_thread = JRuby.reference(thread)
      thread.raise
      thread.join(0.15)
      raise (klass || Timeout::Error), 'execution expired'
    else
      thread.value
    end
  end
end