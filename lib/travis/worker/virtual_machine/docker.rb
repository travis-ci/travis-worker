require 'docker'
require 'fog'
require 'shellwords'
require 'digest/sha1'
require 'benchmark'
require 'travis/support'
require 'travis/worker/ssh/session'

module Travis
  module Worker
    module VirtualMachine
      class Docker
        include Retryable
        include Logging

        class << self
          def vm_count
            Travis::Worker.config.vms.count
          end

          def vm_names
            vm_count.times.map { |num| "#{Travis::Worker.config.vms.name_prefix}-#{num + 1}" }
          end
        end

        log_header { "#{name}:worker:virtual_machine:docker" }

        attr_reader :name, :container

        def initialize(name)
          @name = name
        end

        def create_server(opts = {})
          image = image_for_language(opts[:language])

          info "Using image '#{image} for language #{opts[:language] || '[nil]'}"

          retryable(:tries => 5) do
            @container = create_container(image.id)
            start_container
          end
        end

        def create_container(image_id)
          create_options = {
            'Cmd' => ['/sbin/init'],
            'Image' => image_id,
            'Memory' => (1024 * 1024 * 1024 * (docker_config.memory || 4)),
            'Cpuset' => cpu_set,
            'Hostname' => short_hostname,
          }

          # Allow for opting out of 'Domainname' as this results in lxc-start
          # explosions on docker 1.3.2 (and maybe others?)
          create_options['Domainname'] = domainname unless docker_config.omit_domainname

          if docker_config.expose_ports
            create_options.merge!(
              'ExposedPorts' => {
                '22/tcp' => {}
              }
            )
          end

          ::Docker::Container.create(create_options, connection)
        end

        def start_container
          start_options = { }

          if docker_config.expose_ports
            start_options.merge!(
              'PortBindings' => {
                '22/tcp' => [{ 'HostIp' => nil, 'HostPort' => nil }]
              }
            )
          end

          instrument do
            container.start(start_options)
            Fog.wait_for(10, 2) do
              container.json['State']['Running']
            end
          end
        rescue Timeout::Error, Fog::Errors::TimeoutError => e
          if @container
            error "Docker Container would not boot within 240 seconds : id=#{@container.id}"
          end
          Metriks.meter('worker.vm.provider.docker.boot.timeout').mark
          raise
        rescue Exception => e
          Metriks.meter('worker.vm.provider.docker.boot.error').mark
          error "Booting a Docker Container failed with the following error: #{e.inspect}"
          raise
        end

        def hostname
          @hostname ||= begin
            prefix = Worker.config.host.split('.').first
            "testing-#{prefix}-#{Process.pid}-#{name}.#{Worker.config.host.split('.')[1..-1].join('.')}"
          end
        end

        def short_hostname
          hostname.split('.')[0]
        end

        def domainname
          hostname.split('.')[1..-1].join('.')
        end

        def session
          create_server unless container
          @session ||= Ssh::Session.new(name,
            :host => ssh_host,
            :port => ssh_port,
            :username => 'travis',
            :private_key_path => docker_config.private_key_path,
            :buffer => Travis::Worker.config.shell.buffer,
            :timeouts => Travis::Worker.config.timeouts
          )
        end

        def sandboxed(opts = {})
          create_server(opts)
          yield
        ensure
          session.close if @session
          destroy_server
        end

        def full_name
          "#{Travis::Worker.config.host}:travis-#{name}"
        end

        def docker_config
          Travis::Worker.config.docker || Hashr.new
        end

        def ssh_config
          docker_config.ssh || Hashr.new
        end

        def ssh_host
          ssh_config.host || ip_address
        end

        def ssh_port
          fixed_ssh_host? ? port : 22
        end

        def fixed_ssh_host?
          !!ssh_config.host
        end

        def latest_images
          @latest_images ||= ::Docker::Image.all({}, connection).find_all { |i| image_matches?(i, /^travis:/) }
        end

        def image_for_language(lang)
          lang = Array(lang).first
          mapping = language_mappings[lang.to_s.to_sym] || lang || 'ruby'

          image = if image_override
            latest_images.detect { |i| image_matches?(i, "travis:#{image_override}") }
          else
            latest_images.detect { |i| image_matches?(i, "travis:#{mapping}") }
          end

          image || default_image
        end

        def default_image
          latest_images.detect { |i| image_matches?(i, 'travis:ruby') }
        end

        def image_matches?(image, tag)
          image.info['RepoTags'].any? do |t|
            tag.is_a?(Regexp) ? t =~ tag : t.gsub(/[-_]/, '') == tag.gsub(/[-_]/, '')
          end
        end

        def destroy_server(opts = {})
          ip = ip_address
          stop_container
          remove_container
          @session = nil
        end

        def prepare
          info "using latest templates : '#{latest_images}'"
          info "image override is: '#{image_override}'" if image_override
          info "language mappings include : '#{language_mappings}"
        end

        def connection
          @connection ||= begin
            api = docker_config.api || Hashr.new
            ::Docker::Connection.new("http://#{api.host || 'localhost'}:#{api.port || '4243'}", {})
          end
        end

        private

          def worker_number
            /\w+-(\d+)/.match(name)[1].to_i
          end

          def ip_address
            container.json['NetworkSettings']['IPAddress']
          end

          def port
            container.json['NetworkSettings']['Ports']['22/tcp'][0]['HostPort']
          end

          def cpu_set
            # 1 => 0-1
            offset = worker_number * 2
            "#{offset - 2}-#{offset - 1}"
          end

          def stop_container
            info "stopping container:#{container.id}"
            container.stop
          rescue ::Docker::Error::ServerError => e
            warn "error when trying to stop container : #{e.inspect}"
          end

          def remove_container
            retryable(:tries => 5, :sleep => 3) do
              info "trying to remove container:#{container.id}"
              container.delete(:force => true)
              info "removed container:#{container.id}"
            end
          rescue ::Docker::Error::ServerError, ::Docker::Error::NotFoundError => e
            warn "error when trying to remove container : #{e.inspect}"
          ensure
            @container = nil
          end

          def instrument
            info "Starting container with hostname: #{hostname}"
            time = Benchmark.realtime { yield }
            info "Docker Container started in #{time.round(2)} seconds"
            Metriks.timer('worker.vm.provider.docker.boot').update(time)
          end

          def language_mappings
            @language_mappings ||= Travis::Worker.config.language_mappings
          end

          def image_override
            @image_override ||= Travis::Worker.config.image_override
          end

      end
    end
  end
end
