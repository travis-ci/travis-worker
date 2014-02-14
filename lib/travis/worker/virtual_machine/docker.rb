require 'docker'
require 'fog'
require 'shellwords'
require 'digest/sha1'
require 'benchmark'
require 'travis/support'
require 'travis/worker/ssh/session'

docker = Travis::Worker.config.docker
Docker.url = "http://#{docker.host || 'localhost'}:#{docker.port || '4243'}"
Docker::API_VERSION.replace('1.7')

module Travis
  module Worker
    module VirtualMachine
      # A simple encapsulation of the BlueBox commands used in the
      # Travis Virtual Machine lifecycle.
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

        attr_reader :name, :password, :container

        def initialize(name)
          @name = name
        end

        def create_server(opts = {})
          image = image_for_language(opts[:language])

          info "Using image '#{image} for language #{opts[:language] || '[nil]'}"

          retryable(:tries => 5) do
            create_new_server(image.id)
          end
        end

        def create_new_server(image_id)
          create_options = {
            'Cmd' => ["/sbin/init"],
            'Image' => image_id,
            'CpuShares' => 1,
            'Memory' => 2147483648,
            'Hostname' => hostname,
            'ExposedPorts' => { "22/tcp" => {} }
          }

          start_options = {
            "PortBindings" => {
              "22/tcp" => [{ "HostIp" => nil, "HostPort" => nil }]
            }
          }
          start_options['Privileged'] = true if Travis::Worker.config.docker.privileged_support

          @container = ::Docker::Container.create(create_options)

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

        def session
          create_server unless container
          @session ||= Ssh::Session.new(name,
            :host => host,
            :port => port,
            :username => 'travis',
            :private_key_path => Travis::Worker.config.docker.private_key_path,
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

        def host
          Travis::Worker.config.docker.host
        end

        def port
          container.json["NetworkSettings"]["Ports"]["22/tcp"][0]["HostPort"]
        end

        def latest_images
          @latest_images ||= ::Docker::Image.all.find_all { |i| image_matches?(i, /^travis:/) }
        end

        def image_for_language(lang)
          image = if image_override
            latest_images.detect { |i| image_matches?(i, "travis:#{image_override}") }
          else
            latest_images.detect { |i| image_matches?(i, "travis:#{lang || 'ruby'}") }
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
          stop_container
          remove_container
          @session = nil
        end

        def prepare
          info "using latest templates : '#{latest_images}'"
          info "image override is: '#{image_override}'" if image_override
        end

        private

          def stop_container
            info "stopping container:#{container.id}"
            container.stop
          rescue ::Docker::Error::ServerError => e
            warn "error when trying to stop container : #{e.inspect}"
          end

          def remove_container
            retryable(:tries => 5, :sleep => 3) do
              info "trying to remove container:#{container.id}"
              container.delete
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
