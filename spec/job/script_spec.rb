require "spec_helper"
require "travis/worker/job/script"

describe Travis::Worker::Job::Script do
  let(:payload) { INCOMING_PAYLOADS["build:test-project-1"] }

  before do
    Travis::Worker.config.build.url = "http://example.com"
    Travis::Worker.config.build.api_token = "foobar"

    stub_request(:post, "example.com/script").with(headers: { "Authorization" => "token foobar" }).to_return(body: "#!/bin/bash\necho 'hello world'")
  end

  subject(:script) { described_class.new(payload, "spec").script }

  describe "#script" do
    it "returns a bash script" do
      expect(script).to start_with("#!/bin/bash")
    end

    it "sends the payload to the API" do
      described_class.new({ hello: "world" }, "spec").script

      expect(a_request(:post, "example.com/script").with(headers: { "Content-Type" => "application/json" }, body: /"hello":"world"/)).to have_been_made
    end

    it "sets the Accept header" do
      script

      expect(a_request(:post, "example.com/script").with(headers: { "Accept" => "text/plain" })).to have_been_made
    end

    context "when the API 500s" do
      before do
        stub_request(:post, "example.com/script").with(headers: { "Authorization" => "token foobar" }).to_return(status: 500, body: "this is the error")
      end

      it "raises a CompileError" do
        expect { script }.to raise_error(described_class::CompileError, /this is the error/)
      end
    end

    context "when the API times out" do
      context "but eventually replies" do
        before do
          stub_request(:post, "example.com/script").with(headers: { "Authorization" => "token foobar" }).to_timeout.then.to_return(body: "#!/bin/bash\necho 'hello world'")
        end

        it "returns a bash script" do
          expect(script).to start_with("#!/bin/bash")
        end
      end

      context "and keeps timing out" do
        before do
          stub_request(:post, "example.com/script").with(headers: { "Authorization" => "token foobar" }).to_timeout
        end

        it "raises CompileError" do
          expect { script }.to raise_error(described_class::CompileError, /time/)
        end
      end
    end

    context "when the config for the API isn't set" do
      before do
        # We call WebMock.reset! to remove any stubs that have been made, so
        # any network requests will fail.
        WebMock.reset!

        Travis::Worker.config.build.delete(:url)
        Travis::Worker.config.build.delete(:api_token)
      end

      it "still returns a build script" do
        expect(script).to start_with("#!/bin/bash")
      end
    end
  end
end
