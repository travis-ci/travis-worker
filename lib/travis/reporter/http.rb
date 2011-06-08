require 'em-http-request'
require 'uri'

module Travis
  module Reporter
    class Http < Base
      protected
        def message(type, data)
          path = "/builds/#{build.id}#{'/log' if data.delete(:incremental)}"
          messages.add(type, path, :_method => :put, :build => data)
        rescue Exception => e
          # stdout.puts e.inspect
        end

        def deliver_message(message)
          register_connection(http(message.target).post(:body => message.data, :head => { 'authorization' => auth }))
        end

        def http(path)
          EventMachine::HttpRequest.new([host, path].join('/'))
        end

        def host
          @host ||= config.url || 'http://127.0.0.1'
        end

        def uri
          @uri ||= URI.parse(host)
        end

        def auth
          @auth ||= [uri.user, uri.password]
        end

        def config
          @config ||= Travis::Worker.config.reporter.http || Hashie::Mash.new
        end
    end
  end
end

