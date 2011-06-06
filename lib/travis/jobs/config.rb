module Travis
  module Jobs
    # Build configuration job: GET .travis.yml from github, parses and returns it
    class Config < Base
      def perform
        { :config => read }
      end

      protected

        def read
          YAML.load(File.read(filename)) || {}
        rescue Errno::ENOENT => e
          {}
        end
    end
  end
end
