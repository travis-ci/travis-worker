module Travis
  module Job
    # Carries out task of cloning or synchronizing Git repositories and setting up the stage
    # for build to run on (for example, installing dependencies using Bundler, cleanin up build
    # artifacts and so on).
    #
    # ### Key methods
    #
    # * #checkout
    # * #install
    #
    # @see Travis::Job::Base
    class Repository

      #
      # Behaviors
      #

      include Travis::Shell

      autoload :Config, 'travis/job/repository/config'

      #
      # API
      #

      attr_reader :url
      attr_reader :slug
      attr_reader :config

      # @api public
      def initialize(slug, config)
        @slug   = slug
        @config = Config.new(config)
      end

      # @api public
      def checkout(commit = nil)
        exists? ? fetch : clone
        exec "git checkout -qf #{commit}" if commit
      end

      # @api public
      def install
        install? ? exec("bundle install #{config['bundler_args']}".strip) : true
      end


      # @api plugin
      def raw_url
        "https://raw.github.com/#{slug}"
      end

      #
      # Implementation
      #

      protected

        # @api plugin
        def clone
          exec "git clone #{source} #{Dir.pwd}"
        end

        # @api plugin
        def fetch
          exec 'git clean -fdx'
          exec 'git fetch'
        end

        # @api plugin
        def exists?
          File.directory?('.git')
        end

        # @api plugin
        def install?
          config.gemfile?
        end

        # @api plugin
        def source
          "git://github.com/#{slug}.git"
        end
    end # Repository
  end # Job
end # Travis
