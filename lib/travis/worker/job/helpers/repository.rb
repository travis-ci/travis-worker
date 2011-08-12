module Travis
  module Worker
    module Job
      module Helpers
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

          # @api public
          def initialize(dir, slug)
            @dir    = dir
            @slug   = slug
          end

          # @api public
          def checkout(commit = nil)
            if exists?
              fetch
            else
              clone
              return false unless exists?
            end
            commit ? exec("git checkout -qf #{commit}") : true
          end

          # @api plugin
          def raw_url
            "https://raw.github.com/#{slug}"
          end

          # @api plugin
          def exists?
            exec "test -d .git", :echo => false
          end

          #
          # Implementation
          #

          protected

            # @api plugin
            def clone
              exec 'export GIT_ASKPASS=echo', :echo => false # this makes git interactive auth fail
              exec "git clone --depth=1000 --quiet #{source} #{dir}"
            end

            # @api plugin
            def fetch
              exec 'git clean -fdx'
              exec 'git fetch'
            end

            # @api plugin
            def source
              "git://github.com/#{slug}.git"
            end
        end # Repository
      end
    end # Job
  end # Worker
end # Travis
