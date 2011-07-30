require "pathname"
require "fileutils"
require 'hashr'

module Travis
  module Worker
    module Job
      # Base Job class. Implements the Observer pattern to let reporters register themselves.
      #
      # Every job holds payload data with all the information about build that needs to be executed.
      #
      # ### Key methods
      #
      # * {Base#work!}
      # * {Base#config}
      #
      # @see Travis::Worker::Config
      # @see Travis::Reporter::Base
      # @abstract
      class Base

        #
        # Behaviors
        #

        include Shell

        #
        # API
        #

        class << self
          # @api public
          def base_dir
            @@base_dir ||= Pathname.new(ENV.fetch('BUILD_DIR', '~/builds'))
          end

          # @api public
          def base_dir=(base_dir)
            @@base_dir = Pathname.new(base_dir)
          end
        end

        # @api public
        attr_reader :payload
        # @api plugin
        attr_reader :observers

        # @api public
        def initialize(payload)
          @payload   = Hashr.new(payload)
          @observers = []
        end

        # Runs the build, including necessary setup and post-run routines.
        #
        # Subclasses must implement {#start}, {#perform} and {#finish} methods.
        #
        # @api public
        def work!(shell = nil)
          start
          perform
        rescue
        ensure
          finish
        end

        def repository
          @repository ||= Repository.new(build_dir, payload.repository.slug, build.config ? build.config : {})
        end

        def config
          repository.config ||= Hashr.new
        end

        # @todo We need to pick a more specific name. MK.
        def build
          payload.build ||= Hashr.new
        end

        #
        # Implementation
        #

        protected

          # @api plugin
          def notify(event, *args)
            observers.each do |observer|
              observer.send(:"on_#{event}", *args) if observer.respond_to?(:"on_#{event}")
            end
          end

          def build_dir
            @build_dir ||= self.class.base_dir.join(payload.repository.slug)
          end
      end # Base
    end # Job
  end # Worker
end # Travis
