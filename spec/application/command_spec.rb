
  # describe 'process' do
  #   let(:message) { stub('message', :ack => nil, :properties => stub(:message_id => 1)) }

  #   it 'accepts a :stop command and stops' do
  #     payload = '{ "command": "stop", "workers": ["worker-1", "worker-2"], "force": true }'
  #     manager.expects(:stop).with(:workers => %w(worker-1 worker-2), :force => true)
  #     application.send(:process, message, payload)
  #   end

  #   it 'accepts a :config command and fetches the config' do
  #     payload = '{ "command": "config" }'
  #     manager.expects(:config).with()
  #     application.send(:process, message, payload)
  #   end
  # end

