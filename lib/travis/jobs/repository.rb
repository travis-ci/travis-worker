module Travis
  module Jobs
    class Repository
      include Travis::Shell

      autoload :Config, 'travis/jobs/repository/config'

      attr_reader :url, :config

      def initialize(data, config)
        @url    = data[:url] || ''
        @config = Config.new(config)
      end

      def checkout(commit)
        exists? ? fetch : clone
        exec "git checkout -qf #{commit}" if commit
      end

      def install
        install? ? exec("bundle install #{config['bundler_args']}") : true
      end

      protected

        def clone
          exec 'cd ..', :echo => false
          exec "git clone #{source}"
          exec 'cd -', :echo => false
        end

        def fetch
          exec 'git clean -fdx'
          exec 'git fetch'
        end

        def install?
          config.gemfile?
        end

        def source
          url[0..6] == 'file://' ? path : "#{url.gsub(%r(http://|https://), 'git://')}.git"
        end

        def path
          @path ||= if url =~ %r(https?://github.com)
            URI.parse(url).path
          elsif url =~ %r(file://)
            File.expand_path(url.gsub('file://', ''))
          else
            ''
          end
        end
    end
  end
end
