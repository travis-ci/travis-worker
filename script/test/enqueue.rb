require 'rubygems'
require 'march_hare'
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
    connection.close rescue nil
    true
  end

  def queue_job(payload)
    exchange.publish(payload, :routing_key => 'builds')
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
end

payload = MultiJson.encode({
  'repository' => {
    'slug' => 'svenfuchs/gem-release',
  },
  'build' => {
    'id' => 1,
    'commit' => '313f61b',
    'branch' => 'master',
  },
  'config' => {
    'rvm'    => '1.8.7',
    'script' => 'rake'
  }
})

puts "about to start the queue tester\n\n"

@queue_tester = QueueTester.new
@queue_tester.start

Signal.trap("INT")  { @queue_tester.stop; exit }

puts "queue tester started! \n\n"

while true do
  print 'press enter to trigger a build job for svenfuchs/gem-release, or exit to quit : '

  output = gets.chomp

  @queue_tester.stop && exit if output == 'exit'

  @queue_tester.queue_job(payload)

  puts "build payload sent!\n\n"
end
