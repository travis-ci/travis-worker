require "spec_helper"
require "travis/worker/job/script"

describe Travis::Worker::Job::Script do
  let(:payload) { INCOMING_PAYLOADS["build:test-project-1"] }

  before do
    Travis::Worker.config.build.url = "http://example.com"
    Travis::Worker.config.build.api_token = "foobar"

    stub_request(:post, "example.com/script").with(headers: { "Authorization" => "token foobar" }).to_return(body: "#!/bin/bash\necho 'hello world'")
  end

  describe "#script" do
    it "returns a bash script" do
      expect(described_class.new(payload).script).to start_with("#!/bin/bash")
    end

    context "when the API 500s" do
      before do
        stub_request(:post, "example.com/script").with(headers: { "Authorization" => "token foobar" }).to_return(status: 500, body: "this is the error")
      end

      it "raises a CompileError" do
        expect { described_class.new(payload).script }.to raise_error(described_class::CompileError, /this is the error/)
      end
    end

    context "when the API times out" do
      context "but eventually replies" do
        before do
          stub_request(:post, "example.com/script").with(headers: { "Authorization" => "token foobar" }).to_timeout.then.to_return(body: "#!/bin/bash\necho 'hello world'")
        end

        it "returns a bash script" do
          expect(described_class.new(payload).script).to start_with("#!/bin/bash")
        end
      end

      context "and keeps timing out" do
        before do
          stub_request(:post, "example.com/script").with(headers: { "Authorization" => "token foobar" }).to_timeout
        end

        it "raises CompileError" do
          expect { described_class.new(payload).script }.to raise_error(described_class::CompileError, /time/)
        end
      end
    end
  end
end
