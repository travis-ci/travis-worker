require 'rubygems'
require 'march_hare'
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
    @connection = MarchHare.connect(:host => 'localhost')
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
    @reporting_queue = channel.queue('reporting.jobs', :durable => true, :exculsive => false)
  end

  def subscribe
    @subscription = @reporting_queue.subscribe(:ack => true, :blocking => false) do |headers, payload|
      p [headers.properties.getType, MultiJson.decode(payload)]
      headers.ack
    end
  end
end

puts "starting the reporter\n\n"

@reporter = Reporter.new
@reporter.start

puts "reporter started! send me some logs!! :)\n\n"

Signal.trap("INT")  { @reporter.stop; exit }

while true do
  sleep(1)
end
