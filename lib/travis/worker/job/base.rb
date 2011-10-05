require 'pathname'
require 'fileutils'
require 'hashr'
require 'travis/worker/job/helpers/repository'

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
        attr_reader :reporter

        attr_reader :virtual_machine

        # @api public
        def initialize(payload, virtual_machine)
          @virtual_machine = virtual_machine
          @payload  = Hashr.new(payload)
          @reporter = Reporter.new
        end

        # Runs the build, including necessary setup and post-run routines.
        #
        # Subclasses must implement {#start}, {#perform} and {#finish} methods.
        #
        # @api public
        def work!(shell = nil)
          start
          perform
        rescue => e
          puts "Error : #{e.inspect}"
          e.backtrace.each { |b| puts "  #{b}" }
        ensure
          finish
        end

        def repository
          @repository ||= Helpers::Repository.new(payload.repository.slug)
        end

        def config
          @config ||= build.config = Hashr.new
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
            reporter.send(:"on_#{event}", *args) if reporter.respond_to?(:"on_#{event}")
          end

          def build_dir
            @build_dir ||= self.class.base_dir.join(payload.repository.slug)
          end
      end # Base
    end # Job
  end # Worker
end # Travis
