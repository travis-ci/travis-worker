require 'hot_bunnies'
require 'multi_json'
require 'hashr'

class Reporter
  attr_reader :connection, :channel, :exchange, :reporting_queue

  def initialize
    @connection = @channel = @exchange = @reporting_queue = nil
  end

  def start
    connect
    open_channel
    connect_to_exchange
    create_reporting_queue
    subscribe
  end

  def stop
    connection.close
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

  def create_reporting_queue
    @reporting_queue = channel.queue('reporting', :durable => true, :exculsive => false)
  end

  def subscribe
    @subscription = @reporting_queue.subscribe(:ack => true, :blocking => false) do |headers, payload|
      payload = MultiJson.decode(payload)
      payload = Hashr.new(payload)
      data = payload.log || payload.config
      puts "(#{payload.slug})[Task Id : #{payload.task_id}] #{data.inspect}"
      headers.ack
    end
  end
end

agent = Reporter.new

agent.start
