require 'thor'
require 'hashie'
require 'travis/worker'

module Travis
  class Worker
    class CLI < Thor
      include Shell::Helpers

      CONFIG = {
        :workers => Travis::Worker.config.workers,
        :sources => {
          :lucid =>'http://files.vagrantup.com/lucid32.box'
        },
        :boxes => {
          :lucid => File.expand_path('~/.vagrant/lucid32.box'),
          :base  => File.expand_path('~/.vagrant/base.box')
        },
        :templates => {
          :config  => '.travis.yml',
          :god     => '.travis.god',
          :vagrant => 'Vagrantfile'
        }
      }

      namespace 'travis:worker'
      desc 'install', 'install the travis worker'

      def install
        copy_templates

        download config.sources.lucid, config.boxes.lucid
        add 'worker-1'
        up  'worker-1'

        if config.workers > 1
          package('worker-1', config.boxes.base)

          2.upto(config.workers) do |num|
            add "worker-#{num}", :source => config.boxes.base
            up  "worker-#{num}"
          end
        end
      end

      protected

        def copy_templates
          config.templates.values.each do |filename|
            exec "cp templates/#{filename} #{filename}" unless File.exists?(filename)
          end
        end

        def download(source, target)
          exec "wget #{source} #{target}" unless File.exists?(target)
        end

        def add(name, options = { :source => config.boxes.lucid})
          exec "vagrant box add #{name} #{options[:source]}" unless added?(name)
        end

        def package(name, target)
          unless File.exists?(target)
            exec "vagrant package #{name}"
            exec "mv package.box #{target}"
          end
        end

        def up(name)
          exec "vagrant up #{name}"unless up?(name)
        end

        def added?(name)
          boxes.include?(name)
          # status !~ /#{name}\s*not created/
        end

        def up?(name)
          status =~ /#{name}\s*running/
        end

        def boxes
          @boxes ||= `vagrant box list`.split("\n").map { |name| name.gsub(/[^\w-]/, '').gsub(/0K/, '')  }
        end

        def status
          @status ||= `vagrant status`
        end

        def config
          @config ||= Hashie::Mash.new(CONFIG)
        end

        def exec(cmd)
          system echoize(cmd)
        end
    end
  end
end
