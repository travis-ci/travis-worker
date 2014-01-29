require 'fog'
require 'shellwords'
require 'digest/sha1'
require 'benchmark'
require 'travis/support'
require 'travis/worker/ssh/session'
require 'resolv'

module Travis
  module Worker
    module VirtualMachine
      # A simple encapsulation of the BlueBox commands used in the
      # Travis Virtual Machine lifecycle.
      class BlueBox
        include Retryable
        include Logging

        BLUE_BOX_VM_DEFAULTS = {
          :username  => 'travis',
          :flavor_id => Travis::Worker.config.blue_box.flavor_id,
          :location_id => Travis::Worker.config.blue_box.location_id,
          :ipv6_only => Travis::Worker.config.blue_box.ipv6_only
        }

        DUPLICATE_MATCH_REGEX = /testing-(\w*-?\w+-?\d*-?\d*-\d+-\w+-\d+)-(\d+)/

        class << self
          def vm_count
            Travis::Worker.config.vms.count
          end

          def vm_names
            vm_count.times.map { |num| "#{Travis::Worker.config.vms.name_prefix}-#{num + 1}" }
          end
        end

        log_header { "#{name}:worker:virtual_machine:blue_box" }

        attr_reader :name, :password, :server

        def initialize(name)
          @name = name
        end

        # create a connection
        def connection
          @connection ||= Fog::Compute.new(
            :provider            => 'Bluebox',
            :bluebox_customer_id => Travis::Worker.config.blue_box.customer_id,
            :bluebox_api_key     => Travis::Worker.config.blue_box.api_key
          )
        end

        def create_server(opts = {})
          template = template_for_language(opts[:language])
          
          info "Using template '#{template['description']}' (#{template['id']}) for language #{opts[:language] || '[nil]'}"

          hostname = hostname(opts[:job_id])

          config = BLUE_BOX_VM_DEFAULTS.merge(opts.merge({
            :image_id => template['id'], 
            :hostname => hostname
          }))

          retryable(tries: 3, sleep: 5) do
            destroy_duplicate_servers
            create_new_server(config)
          end
        end

        def create_new_server(opts)
          @password = (opts[:password] = generate_password)

          @server = connection.servers.create(opts)
          info "Booting #{@server.hostname} (#{ip_address})"
          instrument do
            Fog.wait_for(240, 3) do
              begin
                @server.reload
                @server.ready?
              rescue Excon::Errors::HTTPStatusError => e
                mark_api_error(e)
                false
              end
            end
          end
        rescue Timeout::Error, Fog::Errors::TimeoutError => e
          if @server
            error "BlueBox VM would not boot within 240 seconds : id=#{@server.id} state=#{@server.state} vsh=#{vsh_name}"
          end
          Metriks.meter('worker.vm.provider.bluebox.boot.timeout').mark
          raise
        rescue Excon::Errors::HTTPStatusError => e
          mark_api_error(e)
          raise
        rescue Exception => e
          Metriks.meter('worker.vm.provider.bluebox.boot.error').mark
          error "Booting a BlueBox VM failed with the following error: #{e.inspect}"
          raise
        end

        def hostname(suffix)
          prefix = Worker.config.host.split('.').first
          "testing-#{prefix}-#{Process.pid}-#{name}-#{suffix}"
        end

        def session
          unless server
            raise StandardError, 'VM is not currently available'
          end
          @session ||= Ssh::Session.new(name,
            :host => ip_address,
            :port => 22,
            :username => 'travis',
            :password => password,
            :buffer => Travis::Worker.config.shell.buffer,
            :timeouts => Travis::Worker.config.timeouts
          )
        end

        def sandboxed(opts = {})
          create_server(opts)
          yield
        ensure
          session.close if @session
          destroy_server if @server
        end

        def full_name
          "#{Travis::Worker.config.host}:travis-#{name}"
        end

        def ip_address
          server.ips.first['address']
        end

        def vsh_name
          @vsh_name ||= begin
            Timeout::timeout(5) { Resolv::DNS.new.getresource(server.hostname, Resolv::DNS::Resource::IN::TXT).strings.first }
          rescue StandardError => e
            "[unknown]"
          end
        end

        def grouped_templates
          templates = connection.get_templates.body
          templates = templates.find_all { |t| t['public'] == false && t['description'] =~ /^travis-/ }

          grouping_regex = /travis-([\w-]+)-\d{4}-\d{2}-\d{2}-\d{2}-\d{2}/

          grouped = templates.group_by do |t|
            match = grouping_regex.match(t['description'])
            match ? match[1] : nil
          end

          grouped.compact
        end

        def latest_templates
          @latest_templates ||= begin
            latest_templates = {}

            grouped_templates.each do |k,v|
              latest_templates[k] = v.sort { |a, b| b['created'] <=> a['created'] }.first
            end

            latest_templates
          end
        end

        def template_for_language(lang)
          return latest_templates[template_override] if template_override

          lang = Array(lang).first
          mapping = if lang
            language_mappings[lang] || lang.gsub('_', '-')
          else
            'ruby'
          end

          latest_templates[mapping] || latest_templates['ruby']
        rescue => e
          error "Error figuring out what template to use: #{e.inspect}"
          latest_templates['ruby']
        end

        def destroy_server(opts = {})
          destroy_vm(server)
        ensure
          @server = nil
          @session = nil
        end

        def prepare
          info "Blue Box API adapter prepared"
        end

        private

          def destroy_duplicate_servers
            duplicate_servers.each do |server|
              info "destroying duplicate server #{server.hostname}"
              destroy_vm(server)
            end
          end

          def duplicate_servers
            connection.servers.select do |server|
              DUPLICATE_MATCH_REGEX.match(server.hostname) do |match|
                match[1] == "#{Worker.config.host.split('.').first}-#{Process.pid}-#{name}"
              end
            end
          end

          def instrument
            info "Provisioning a BlueBox VM"
            time = Benchmark.realtime { yield }
            info "BlueBox VM provisioned in #{time.round(2)} seconds"
            Metriks.timer('worker.vm.provider.bluebox.boot').update(time)
          end

          def mark_api_error(error)
            Metriks.meter("worker.vm.provider.bluebox.api.error.#{error.response[:status]}").mark
            error "BlueBox API returned error code #{error.response[:status]} : #{error.inspect}"
          end

          def destroy_vm(vm)
            debug "vm is in #{vm.state} state"
            info "destroying the VM"
            retryable(tries: 3, sleep: 5) do
              vm.destroy
            end
          rescue Fog::Compute::Bluebox::NotFound => e
            warn "went to destroy the VM but it didn't exist :/ : #{e.inspect}"
          rescue Excon::Errors::HTTPStatusError => e
            warn "went to destroy the VM but there was an http status error : #{e.inspect}"
          rescue Excon::Errors::InternalServerError => e
            warn "went to destroy the VM but there was an internal server error : #{e.inspect}"
            mark_api_error(e)
          end

          def generate_password
            Digest::SHA1.base64digest(OpenSSL::Random.random_bytes(30)).gsub(/[\&\+\/\=\\]/, '')[0..19]
          end

          def language_mappings
            @language_mappings ||= Travis::Worker.config.language_mappings
          end

          def template_override
            @template_override ||= Travis::Worker.config.template_override
          end

      end
    end
  end
end
