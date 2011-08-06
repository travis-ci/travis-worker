module Travis
  module Worker
    module Job
      # Carries out task of cloning or synchronizing Git repositories and setting up the stage
      # for build to run on (for example, installing dependencies using Bundler, cleanin up build
      # artifacts and so on).
      #
      # ### Key methods
      #
      # * #checkout
      #
      # @see Travis::Job::Base
      class Repository

        #
        # Behaviors
        #

        include Shell

        #
        # API
        #

        attr_reader :dir
        attr_reader :slug
        attr_reader :config

        # @api public
        def initialize(dir, slug, config)
          @dir    = dir
          @slug   = slug
        end

        # @api public
        def checkout(commit = nil)
          exists? ? fetch : clone
          exec "git checkout -qf #{commit}" if commit
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
            exec 'export GIT_ASKPASS=echo', :echo => false # this makes git interactive auth fail
            exec "mkdir -p #{dir}", :echo => false
            exec "git clone --depth=1000 --quiet #{source} #{dir}"
          end

          # @api plugin
          def fetch
            exec 'git clean -fdx'
            exec 'git fetch'
          end

          # @api plugin
          def exists?
            exec "test -d .git", :echo => false
          end

          # @api plugin
          def source
            "git://github.com/#{slug}.git"
          end
      end # Repository
    end # Job
  end # Worker
end # Travis
