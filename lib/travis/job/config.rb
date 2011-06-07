module Travis
  module Job
    # Build configuration job: read .travis.yml and return it
    class Config < Base
      def perform
        chdir do
          repository.checkout(build.commit)
          { :config => read }
        end
      end

      protected

        # TODO instead we could just do an http request to the github raw file here
        def read
          YAML.load(File.read('.travis.yml')) || {}
        rescue Errno::ENOENT => e
          {}
        end
    end
  end
end
