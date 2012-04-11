shared_context "hot_bunnies connection" do
  let(:connection) { HotBunnies.connect(:hostname => "127.0.0.1") }
  after(:all)      { connection.close }
end
