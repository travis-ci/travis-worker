module Travis
  module Jobs
    # Clones/fetches the repository, installs the bundle and runs the build
    # scripts using the default or specified rvm ruby.
    class Build < Base
      attr_reader :log, :result

      def initialize(payload)
        super
        observers << self
        @log = ''
      end

      protected

        def perform
          status = chdir { build! ? 0 : 1 }
          puts "\nDone. Build script exited with: #{status}"
          { :build => { :log => log, :status => status } }
        end

        def build!
          repository.checkout(payload['build']['commit'])
          repository.install && run_scripts
        end

        def run_scripts
          %w{before_script script after_script}.each do |type|
            script = config.send(type)
            break false if script.nil? || !run_script(script)
          end
        end

        def run_script(script)
          Array(script).each do |script|
            break false unless exec(script)
          end
        end

        def chdir(&block)
          FileUtils.mkdir_p(build_dir)
          Dir.chdir(build_dir, &block)
        end

        def on_data(data)
          @log << data
        end

        def start
          super(data[:build].merge(:finished_at => Time.now))
        end

        def finish(data)
          super(data[:build].merge(:finished_at => Time.now))
        end
      end
  end
end
