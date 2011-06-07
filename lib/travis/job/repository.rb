module Travis
  module Job
    class Repository
      include Travis::Shell

      autoload :Config, 'travis/job/repository/config'

      attr_reader :url, :path, :config

      def initialize(url, config)
        @url    = url
        @path   = URI.parse(url).path
        @config = Config.new(config)
      end

      def checkout(commit = nil)
        exists? ? fetch : clone
        exec "git checkout -qf #{commit}" if commit
      end

      def install
        install? ? exec("bundle install #{config['bundler_args']}".strip) : true
      end

      protected

        def clone
          exec "git clone #{source} #{Dir.pwd}"
        end

        def fetch
          exec 'git clean -fdx'
          exec 'git fetch'
        end

        def exists?
          File.directory?('.git')
        end

        def install?
          config.gemfile?
        end

        def source
          "#{url.gsub(%r(http://|https://), 'git://')}.git"
        end
    end
  end
end
