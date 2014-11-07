require 'yaml'
require 'hashr'
require 'socket'
require 'travis/worker/virtual_machine'

module Travis
  module Worker
    class Config < Hashr
      module Vms
        def count
         self[:count]
        end

        def name_prefix
          self[:name_prefix] || "travis-#{Travis::Worker.config.env}"
        end

        def names
          (1..count.to_i).map { |num| "#{name_prefix}-#{num}" }
        end
      end

        define amqp:      { username: 'guest', password: 'guest', host: 'localhost' },
               heartbeat: { interval: 10 },
               log_level: 'info',
               logger:    { time_format: '%Y-%m-%dT%H:%M:%S.%6N%:z', process_id: true, thread_id: true },
               queue:     'builds.linux',
               logging_channel: 'reporting.jobs.logs',
               shell:     { buffer: 0.5 },
               timeouts:  { build_script: 5, hard_limit: 50 * 60, log_silence: 10 * 60 },
               shutdown_timeout: 3600,
               vms:       { provider: 'blue_box', count: 1, _include: Vms },
               limits:    { log_length: 4, log_chunk_size: 9216 },
               language_mappings: { },
               build:     {}

      def name
        @name ||= host.split('.').first
      end

      def names
        @names ||= VirtualMachine.provider.vm_names.map { |name| name.gsub(/^travis-/, '') }
      end

      def host
        @host ||= self[:host] || Socket.gethostname
      end

      def initialize
        super(read)
      end

      protected

        LOCATIONS = ['./config/', '~/.']

        def read
          local = read_yml(path)
          env   = local['env']
          local = local[env] || {}
          read_yml(path('base')).deep_merge(read_yml(path(env)).deep_merge(local.merge('env' => env)))
        end

        def read_yml(file_path)
          YAML.load_file(File.expand_path(file_path)) || {}
        end

        def config_filename(environment)
          ['worker', environment, 'yml'].compact.join('.')
        end

        def path(environment = nil)
          filename = config_filename(environment)
          paths    = LOCATIONS.map { |p| "#{p}#{filename}" }

          if existing_path = paths.detect { |p| File.exists?(p) }
            existing_path
          else
            raise "Could not find a configuration file. Valid paths are: #{paths.join(', ')}"
          end
        end
    end
  end
end
