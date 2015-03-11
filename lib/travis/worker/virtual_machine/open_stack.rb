require 'fog'
require 'shellwords'
require 'securerandom'
require 'benchmark'
require 'travis/support'
require 'travis/worker/ssh/session'
require 'resolv'
require 'travis/worker/virtual_machine/blue_box/template'

module Travis
  module Worker
    module VirtualMachine
      class OpenStack
        include Retryable
        include Logging

        DUPLICATE_MATCH = /testing-(\w*-?\w+-?\d*-?\d*-\d+-\w+-\d+)-(\d+)/

        MINIMAL_TEMPLATE_ID = '8695dfe8-2312-4d58-8371-ee6ada389c67'

        class << self
          def vm_count
            Travis::Worker.config.vms.count
          end

          def vm_names
            vm_count.times.map { |num| "#{Travis::Worker.config.vms.name_prefix}-#{num + 1}" }
          end
        end

        log_header { "#{name}:worker:virtual_machine:open_stack" }

        attr_reader :name, :password, :server

        def initialize(name)
          @name = name
        end

        # create a connection
        def connection
          @connection ||= Fog::Compute.new(
            provider: :openstack,
            openstack_api_key:  Travis::Worker.config.open_stack.api_key,
            openstack_username: Travis::Worker.config.open_stack.username,
            openstack_auth_url: Travis::Worker.config.open_stack.auth_url,
            openstack_tenant:   Travis::Worker.config.open_stack.tenant
          )
        end

        def create_server(opts = {})
          hostname = hostname(opts[:job_id])

          config = open_stack_vm_defaults.merge(opts.merge({
            :image_ref => MINIMAL_TEMPLATE_ID,
            :name => hostname
          }))

          retryable(tries: 3, sleep: 5) do
            destroy_duplicate_servers
            create_new_server(config)
          end
        end

        def create_new_server(opts)
          @password = (opts[:password] = generate_password)

          user_data  = %Q{#! /bin/bash\nsudo useradd travis -m -s /bin/bash || true\n}
          user_data += %Q{echo travis:#{opts[:password]} | sudo chpasswd\n} if opts[:password]
          user_data += %Q{sudo sed -i '/travis/d' /etc/sudoers\n}
          user_data += %Q{echo "travis ALL=(ALL) NOPASSWD:ALL" | sudo tee -a /etc/sudoers\n}
          user_data += %Q{sudo sed -i '/PasswordAuthentication/ d' /etc/ssh/sshd_config\n}
          user_data += %Q{echo 'PasswordAuthentication yes' | tee -a /etc/ssh/sshd_config\n}
          user_data += %Q{sudo service ssh restart}

          opts[:user_data] = user_data
          opts[:key_name]  = Travis::Worker.config.open_stack.key_name

          info "opts: #{opts}"
          @server = connection.servers.create(opts)
          instrument do
            Fog.wait_for(300, 3) do
              begin
                server.reload
                server.ready?

                info "Booted #{server.name} (#{ip_address})"

              rescue Excon::Errors::HTTPStatusError => e
                mark_api_error(e)
                false
              end
            end
          end
        rescue Timeout::Error, Fog::Errors::TimeoutError => e
          if server
            error "OpenStack VM would not boot within 240 seconds : id=#{server.id} state=#{server.state} vsh=#{server.vsh_id}"
          end
          Metriks.meter("worker.vm.provider.openstack.boot.timeout.#{server.vsh_id}").mark
          raise
        rescue Excon::Errors::HTTPStatusError => e
          mark_api_error(e)
          raise
        rescue Exception => e
          Metriks.meter('worker.vm.provider.openstack.boot.error').mark
          error "Booting a OpenStack VM failed with the following error: #{e.inspect}"
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
          destroy_server if server
        end

        def open_stack_vm_defaults
          {
            :username  => 'travis',
            :flavor_ref => Travis::Worker.config.open_stack.flavor_id,
            :nics => [{ net_id: Travis::Worker.config.open_stack.internal_network_id }]
          }
        end

        def full_name
          "#{Travis::Worker.config.host}:travis-#{name}"
        end

        def ip_address
          return @ip_address if @ip_address

          # assume that server is ready
          connection.allocate_address(Travis::Worker.config.open_stack.external_network_id)
          connection.associate_address(server.id, ip.body["floating_ip"]["ip"])

          @ip_address = server.floating_ip_addresses.first
        end

        def grouped_templates(group = nil, dist = nil)
          templates = select_matching_templates(create_templates(fetch_templates), group, dist)

          grouped = templates.group_by do |t|
            [t.dist, t.group, t.template]
          end
        end

        def latest_templates(group = nil, dist = nil)
          template_list = {}

          grouped_templates(group, dist).each do |k,v|
            template_list[k] = v.sort { |a, b| b.created <=> a.created }.first
          end

          template_list
        end

        def template_for_language(lang, group = nil, dist = nil)
          return latest_templates(group, dist)[template_override] if template_override

          lang = Array(lang).first
          mapping = if lang
            language_mappings[lang] || lang.gsub('_', '-')
          else
            'ruby'
          end

          select_template(mapping, group, dist)
        rescue => e
          error "Error figuring out what template to use: #{e.inspect}"
          latest_templates(group)[[nil, nil, 'ruby']]
        end

        def destroy_server(opts = {})
          destroy_vm(server)
        ensure
          server = nil
          @session = nil
        end

        def prepare
          info "OpenStack API adapter prepared"
        end

        private

          def destroy_duplicate_servers
            duplicate_servers.each do |server|
              info "destroying duplicate server #{server.name}"
              destroy_vm(server)
            end
          end

          def duplicate_servers
            connection.servers.select do |server|
              DUPLICATE_MATCH.match(server.name) do |match|
                match[1] == "#{Worker.config.host.split('.').first}-#{Process.pid}-#{name}"
              end
            end
          rescue Excon::Errors::HTTPStatusError => e
            warn "could not retrieve the current VM list : #{e.inspect}"
            mark_api_error(e)
            raise
          end

          def instrument
            info "Provisioning a OpenStack VM"
            time = Benchmark.realtime { yield }
            info "OpenStack VM provisioned in #{time.round(2)} seconds"
            Metriks.timer('worker.vm.provider.openstack.boot').update(time)
          end

          def mark_api_error(error)
            Metriks.meter("worker.vm.provider.openstack.api.error.#{error.response[:status]}").mark
            error "OpenStack API returned error code #{error.response[:status]} : #{error.inspect}"
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

          def fetch_templates
            retryable(tries: 3, sleep: 5) do
              begin
                connection.get_templates.body
              rescue Excon::Errors::HTTPStatusError => e
                warn "could not fetch template list due to an http status error : #{e.inspect}"
                mark_api_error(e)
                raise
              end
            end
          end

          # given JSON response from the server, put corresponding Template objects into an array
          def create_templates(json_response)
            json_response.map do |t|
              obj = Template.new(t)
            end
          end

          def generate_password
            SecureRandom.base64 12
          end

          def language_mappings
            @language_mappings ||= Travis::Worker.config.language_mappings
          end

          def template_override
            @template_override ||= Travis::Worker.config.template_override
          end

          # given group and dist, select templates that match criteria
          def select_matching_templates(template_objects, group, dist)
            templates = template_objects.find_all do |t|
              ! t.public && t.description =~ /^travis-/ && t.description =~ /\b#{group}\b/ && t.description =~ /\b#{dist}\b/
            end

            if templates.empty?
              templates = template_objects.find_all do |t|
                ! t.public && t.description =~ /^travis-/ && t.description =~ /\b(#{group}|#{dist})\b/
              end
            end

            if templates.empty?
              templates = template_objects.find_all do |t|
                ! t.public && t.description =~ /^travis-/
              end
            end

            templates
          end

          # this method dictates the precedence of template selection
          def select_template(mapping, group, dist)
            # first, if group is given, find the matching template
            # if group is nil, look for DEFAULT_TEMPLATE_GROUP
            latest_templates(group, dist)[[dist, (group || DEFAULT_TEMPLATE_GROUP), mapping]] ||
            latest_templates(group, dist)[[nil,  (group || DEFAULT_TEMPLATE_GROUP), mapping]] ||
            # if no matching template is found, look for DEFAULT_TEMPLATE_GROUP
            latest_templates(group, dist)[[dist, DEFAULT_TEMPLATE_GROUP,            mapping]] ||
            latest_templates(group, dist)[[nil,  DEFAULT_TEMPLATE_GROUP,            mapping]] ||
            # if no template with group DEFAULT_TEMPLATE_GROUP is found, then look for template without group
            latest_templates(group, dist)[[dist, nil,                               mapping]] ||
            latest_templates(group, dist)[[nil,  nil,                               mapping]] ||
            # go through the same checkdown list for unrecognized language, falling back to DEFAULT_TEMPLATE_LANGUAGE
            latest_templates(group, dist)[[dist, (group || DEFAULT_TEMPLATE_GROUP), DEFAULT_TEMPLATE_LANGUAGE ]] ||
            latest_templates(group, dist)[[nil,  (group || DEFAULT_TEMPLATE_GROUP), DEFAULT_TEMPLATE_LANGUAGE ]] ||
            latest_templates(group, dist)[[dist, DEFAULT_TEMPLATE_GROUP,            DEFAULT_TEMPLATE_LANGUAGE ]] ||
            latest_templates(group, dist)[[nil,  DEFAULT_TEMPLATE_GROUP,            DEFAULT_TEMPLATE_LANGUAGE ]] ||
            latest_templates(group, dist)[[dist, nil,                               DEFAULT_TEMPLATE_LANGUAGE ]] ||
            latest_templates(group, dist)[[nil,  nil,                               DEFAULT_TEMPLATE_LANGUAGE ]]
          end

      end
    end
  end
end