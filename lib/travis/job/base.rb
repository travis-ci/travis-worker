require "pathname"
require "fileutils"

module Travis
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

      include Travis::Shell


      #
      # API
      #

      class << self
        # @api public
        def base_dir
          @@base_dir ||= Pathname.new(ENV.fetch("TRAVIS_WORKER_BUILDS_PATH", '/tmp/travis/builds'))
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
        @payload   = Hashie::Mash.new(payload)
        @observers = []
      end

      # Runs the build, including necessary setup and post-run routines.
      #
      # Subclasses must implement {#start}, {#perform} and {#finish} methods.
      #
      # @api public
      def work!
        start
        perform
        finish
      end

      def repository
        @repository ||= Repository.new(payload.repository.slug, build.config)
      end

      def config
        repository.config ||= Hashie::Mash.new
      end

      # @todo We need to pick a more specific name. MK.
      def build
        payload.build ||= Hashie::Mash.new
      end



      #
      # Implementation
      #

      protected

      # @api plugin
      def start
      end

      # @api plugin
      def update(data)
      end

      # @api plugin
      def finish
      end

      # @api plugin
      def notify(event, *args)
        observers.each do |observer|
          observer.send(:"on_#{event}", self, *args) if observer.respond_to?(:"on_#{event}")
        end
      end

      # @api private
      def chdir(&block)
        FileUtils.mkdir_p(build_dir)
        Dir.chdir(build_dir, &block)
      end

      # @api plugin
      def build_dir
        @build_dir ||= self.class.base_dir.join(repository.slug)
      end
    end # Base
  end # Job
end # Travis
