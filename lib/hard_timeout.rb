require 'timeout'

# inspired by https://gist.github.com/1356797
# and @headius helped me modify it to this
#
# for safe keeping : https://gist.github.com/f489c48601060899ecff

module HardTimeout
  def self.timeout(sec, klass=nil)
    return yield(sec) if sec == nil or sec.zero?
    thread = Thread.new { yield(sec) }

    if thread.join(sec).nil?
      thread.kill
      raise (klass || Timeout::Error), 'execution expired'
    else
      thread.value
    end
  end
end