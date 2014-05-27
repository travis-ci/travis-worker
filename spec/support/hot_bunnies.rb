shared_context "march_hare connection" do
  let(:connection) { MarchHare.connect(:hostname => "127.0.0.1") }
  after(:each)     { connection.close }
end
