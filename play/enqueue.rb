require 'hot_bunnies'
require 'multi_json'
require 'hashr'


class QueueTester
  attr_reader :connection, :channel, :exchange, :reporting_queue

  def initialize
    @connection = @channel = @exchange = @reporting_queue = nil
  end

  def start
    connect
    open_channel
    connect_to_exchange
  end

  def stop
    connection.close
  end

  def queue_job(payload)
    exchange.publish(payload, :routing_key => 'builds')
  end

  private
  def connect
    @connection = HotBunnies.connect(:host => 'localhost')
  end

  def open_channel
    @channel.close if @channel

    @channel = connection.create_channel
    @channel.prefetch = 1
  end

  def connect_to_exchange
    @exchange = channel.exchange('', :type => :direct, :durable => true)
  end
end

payload = {
  'repository' => {
    'slug' => 'svenfuchs/gem-release',
  },
  'build' => {
    'id' => 1,
    'commit' => '313f61b',
    'branch' => 'master',
    'config' => {
      'rvm'    => '1.8.7',
      'script' => 'rake'
    }
  }
}

queue_tester = QueueTester.new
queue_tester.start
queue_tester.queue_job(MultiJson.encode(payload))
