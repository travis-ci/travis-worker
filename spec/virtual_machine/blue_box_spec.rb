require 'spec_helper'
require 'travis/worker/virtual_machine/blue_box'
require 'metriks'
require 'metriks/reporter/librato_metrics'
require 'fog/bluebox/models/compute/server'
require 'travis/worker/virtual_machine/blue_box/template'
require 'json'

describe Travis::Worker::VirtualMachine::BlueBox do
  let(:ruby_template_attr)                 { JSON.parse '{"id":"7f3bb248-7bf2-41aa-a8c2-d00f426803ee","status":"stored","description":"travis-ruby-2014-08-28-20-46-cf95d0f","public":false,"locations":["016cdf0f-821b-4bed-8b9c-cd46f02c2363"],"created":"2014-08-28T13:46:37-07:00"}' }
  let(:old_ruby_template_attr)             { JSON.parse '{"id":"7f3bb233-7bf2-41aa-a8c2-d00f426803ee","status":"stored","description":"travis-ruby-2014-08-18-20-46-cf95d0f","public":false,"locations":["016cdf0f-821b-4bed-8b9c-cd46f02c2363"],"created":"2014-08-18T13:46:37-07:00"}' }
  let(:update_ruby_template_attr)          { JSON.parse '{"id":"7f3bb567-7bf2-41aa-a8c2-d00f426803ee","status":"stored","description":"travis-update-ruby-2014-08-18-20-46-cf95d0f","public":false,"locations":["016cdf0f-821b-4bed-8b9c-cd46f02c2363"],"created":"2014-08-18T13:46:37-07:00"}' }
  let(:update_trusy_ruby_template_attr)    { JSON.parse '{"id":"7f3bb567-7bf2-41aa-a8c2-d00f426803ee","status":"stored","description":"travis-update-trusty-ruby-2014-08-18-20-46-cf95d0f","public":false,"locations":["016cdf0f-821b-4bed-8b9c-cd46f02c2363"],"created":"2014-08-18T13:46:37-07:00"}' }
  let(:perl_template_attr)                 { JSON.parse '{"id":"4d0e7e03-3230-40f8-817a-6e8271e39e0c","status":"stored","description":"travis-perl-2014-08-28-22-29-cf95d0f","public":false,"locations":["016cdf0f-821b-4bed-8b9c-cd46f02c2363"],"created":"2014-08-28T15:29:00-07:00"}' }
  let(:update_perl_template_attr)          { JSON.parse '{"id":"4d0e7e03-3230-40f8-817a-6e8271e3cafe","status":"stored","description":"travis-update-perl-2014-08-28-22-29-cf95d0f","public":false,"locations":["016cdf0f-821b-4bed-8b9c-cd46f02c2363"],"created":"2014-08-28T15:29:00-07:00"}' }
  let(:update_trusty_perl_template_attr)   { JSON.parse '{"id":"4d0e7e03-3230-40f8-817a-6e8271e3aaaa","status":"stored","description":"travis-update-trusty-perl-2014-08-28-22-29-cf95d0f","public":false,"locations":["016cdf0f-821b-4bed-8b9c-cd46f02c2363"],"created":"2014-08-28T15:29:00-07:00"}' }
  let(:nodejs_template_attr)               { JSON.parse '{"id":"ff7bd191-f433-4830-b7aa-facdba33674b","status":"stored","description":"travis-node-js-2014-08-28-20-11-cf95d0f","public":false,"locations":["016cdf0f-821b-4bed-8b9c-cd46f02c2363"],"created":"2014-08-28T13:11:32-07:00"}' }
  let(:update_nodejs_template_attr)        { JSON.parse '{"id":"ff7bd191-f433-4830-b7aa-facdba33aeda","status":"stored","description":"travis-update-node-js-2014-08-28-20-11-cf95d0f","public":false,"locations":["016cdf0f-821b-4bed-8b9c-cd46f02c2363"],"created":"2014-08-28T13:11:32-07:00"}' }
  let(:update_trusty_nodejs_template_attr) { JSON.parse '{"id":"ff7bd191-f433-4830-b7aa-facdba336333","status":"stored","description":"travis-trusty-update-node-js-2014-08-28-20-11-cf95d0f","public":false,"locations":["016cdf0f-821b-4bed-8b9c-cd46f02c2363"],"created":"2014-08-30T13:11:32-07:00"}' }

  let(:base_templates) { [ruby_template_attr, old_ruby_template_attr, nodejs_template_attr, perl_template_attr, update_nodejs_template_attr, update_trusty_nodejs_template_attr] }

  describe "#new" do
    blue_box = described_class.new('blue_box')
  end

  describe "#create_server" do
    context 'when every call to Blue Box succeeds' do
      let(:response_body) { base_templates.to_json }

      let(:blue_box) { described_class.new 'blue_box' }

      before :example do
        stub_request(:get, 'https://boxpanel.bluebox.net/api/block_templates.json').
          to_return(:status => 200, :headers => {}, :body => response_body)
        stub_request(:get, 'https://boxpanel.bluebox.net/api/blocks.json').
          to_return(:status => 200, :headers => {}, :body => <<-BODY)
            [
              {"id":"1877a1e4-c3d6-4674-8534-54d48f4683e2","hostname":"testing-worker-linux-10-1-14390-linux-1-34724668.c45665.blueboxgrid.com","vsh_id":"f2507fb8-babf-4dbf-8fe5-34e0a6ff7243","description":"3 GB RAM + 20 GB Disk","memory":3221225472,"storage":21474836480,"cpu":1.5,"ips":[{"address":"2607:f700:8001:147:f7ce:d2c0:21fe:1909"}],"lb_applications":[],"status":"building","location_id":"77390972-b539-4766-b891-fa6c9bb8b76e"},
              {"id":"be26d9df-0fbe-416d-989c-72649cc0c381","hostname":"testing-worker-linux-10-1-14390-linux-10-34695320.c45665.blueboxgrid.com","vsh_id":"a2889456-c585-4d4f-aa93-40010bd0cc8a","description":"3 GB RAM + 20 GB Disk","memory":3221225472,"storage":21474836480,"cpu":1.5,"ips":[{"address":"2607:f700:8000:12d:89e:f3bc:143e:8c55"}],"lb_applications":[],"status":"running","location_id":"77390972-b539-4766-b891-fa6c9bb8b76e"}
            ]
          BODY
        stub_request(:get, Addressable::Template.new("https://boxpanel.bluebox.net/api/blocks/{image_id}.json")).
          to_return(:status => 200, :headers => {}, :body => '{"id":"deadbeef-c3d6-4674-8534-54d48f4683e2","hostname":"testing-worker-linux-10-1-14390-linux-1-34724668.c45665.blueboxgrid.com","vsh_id":"f2507fb8-babf-4dbf-8fe5-34e0a6ff7243","description":"3 GB RAM + 20 GB Disk","memory":3221225472,"storage":21474836480,"cpu":1.5,"ips":[{"address":"2607:f700:8001:147:f7ce:d2c0:21fe:1909"}],"lb_applications":[],"status":"building","location_id":"77390972-b539-4766-b891-fa6c9bb8b76e"}')
        stub_request(:post, 'https://boxpanel.bluebox.net/api/blocks.json').
          with(:query => hash_including({})).
          to_return(:status => 200, :headers => {}, :body => '{"id":"1877a1e4-c3d6-4674-8534-54d48f4683e2","ips": [{"address":"2607:f700:8000:12d:89e:f3bc:143e:8c55"}],"memory":3221225472,"storage":21474836480,"hostname":"testing-worker-linux-10-1-14390-linux-1-34724668.c45665.blueboxgrid.com","cpu":1.5,"status":"queued"}')

        Fog::Compute::Bluebox::Server.any_instance.stubs(:ready?).returns(true)
      end

      context 'when no arguments are given' do
        it 'returns without errors' do
          expect(blue_box.create_server).to be_truthy
        end
      end


    end
  end

  describe '#template_for_language' do
    context 'when a wide range of templates are available' do
      let(:response_body) { base_templates.to_json }

      let(:blue_box) { described_class.new('blue_box') }

      before :example do
        stub_request(:get, 'https://boxpanel.bluebox.net/api/block_templates.json').
          to_return(:status => 200, :headers => {}, :body => response_body)
        stub_request(:get, 'https://boxpanel.bluebox.net/api/blocks.json').
          to_return(:status => 200, :headers => {}, :body => <<-BODY)
            [
              {"id":"1877a1e4-c3d6-4674-8534-54d48f4683e2","hostname":"testing-worker-linux-10-1-14390-linux-1-34724668.c45665.blueboxgrid.com","vsh_id":"f2507fb8-babf-4dbf-8fe5-34e0a6ff7243","description":"3 GB RAM + 20 GB Disk","memory":3221225472,"storage":21474836480,"cpu":1.5,"ips":[{"address":"2607:f700:8001:147:f7ce:d2c0:21fe:1909"}],"lb_applications":[],"status":"building","location_id":"77390972-b539-4766-b891-fa6c9bb8b76e"},
              {"id":"be26d9df-0fbe-416d-989c-72649cc0c381","hostname":"testing-worker-linux-10-1-14390-linux-10-34695320.c45665.blueboxgrid.com","vsh_id":"a2889456-c585-4d4f-aa93-40010bd0cc8a","description":"3 GB RAM + 20 GB Disk","memory":3221225472,"storage":21474836480,"cpu":1.5,"ips":[{"address":"2607:f700:8000:12d:89e:f3bc:143e:8c55"}],"lb_applications":[],"status":"running","location_id":"77390972-b539-4766-b891-fa6c9bb8b76e"}
            ]
          BODY
        stub_request(:get, Addressable::Template.new("https://boxpanel.bluebox.net/api/blocks/{image_id}.json")).
          to_return(:status => 200, :headers => {}, :body => '{"id":"deadbeef-c3d6-4674-8534-54d48f4683e2","hostname":"testing-worker-linux-10-1-14390-linux-1-34724668.c45665.blueboxgrid.com","vsh_id":"f2507fb8-babf-4dbf-8fe5-34e0a6ff7243","description":"3 GB RAM + 20 GB Disk","memory":3221225472,"storage":21474836480,"cpu":1.5,"ips":[{"address":"2607:f700:8001:147:f7ce:d2c0:21fe:1909"}],"lb_applications":[],"status":"building","location_id":"77390972-b539-4766-b891-fa6c9bb8b76e"}')
        stub_request(:post, 'https://boxpanel.bluebox.net/api/blocks.json').
          with(:query => hash_including({})).
          to_return(:status => 200, :headers => {}, :body => '{"id":"1877a1e4-c3d6-4674-8534-54d48f4683e2","ips": [{"address":"2607:f700:8000:12d:89e:f3bc:143e:8c55"}],"memory":3221225472,"storage":21474836480,"hostname":"testing-worker-linux-10-1-14390-linux-1-34724668.c45665.blueboxgrid.com","cpu":1.5,"status":"queued"}')
      end

      context 'given valid template name' do
        subject { blue_box.template_for_language('ruby') }
        it 'chooses the most recent template' do
          expect(subject).to eq(
            Travis::Worker::VirtualMachine::BlueBox::Template.new ruby_template_attr
          )
        end
      end

      context 'given valid template name and group' do
        subject { blue_box.template_for_language('node-js', 'update') }
        it 'chooses the correct one' do
          expect(subject).to eq(
            Travis::Worker::VirtualMachine::BlueBox::Template.new update_nodejs_template_attr
          )
        end
      end

      context 'given valid template name, group and dist' do
        subject { blue_box.template_for_language('node-js', 'update', 'trusty')}
        it 'chooses the correct one' do
          expect(subject).to eq(
            Travis::Worker::VirtualMachine::BlueBox::Template.new update_trusty_nodejs_template_attr
          )
        end
      end

      context 'given nonexistent name' do
        subject { blue_box.template_for_language('foobar') }
        it 'chooses default (Ruby) template' do
          expect(subject).to eq(
            Travis::Worker::VirtualMachine::BlueBox::Template.new ruby_template_attr
          )
        end
      end

      context 'given valid template name and nonexistent group name' do
        subject { blue_box.template_for_language('ruby', 'foobar') }
        it 'chooses default (Ruby) template' do
          expect(subject).to eq(
            Travis::Worker::VirtualMachine::BlueBox::Template.new ruby_template_attr
          )
        end
      end

      context 'given valid template name and group, but nonexistent dist name' do
        let(:response_body) { (base_templates << update_ruby_template_attr).to_json }

        subject { blue_box.template_for_language('ruby', 'update', 'foobar') }
        it 'chooses default (Ruby) update template' do
          expect(subject).to eq(
            Travis::Worker::VirtualMachine::BlueBox::Template.new update_ruby_template_attr
          )
        end
      end
    end
  end
end
