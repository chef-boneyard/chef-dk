require "bundler"
require "omnibus"
require_relative "../build-chef-dk-gem"

module BuildChefDKGem
  class GemInstallSoftwareDef
    def self.define(software, software_filename)
      new(software, software_filename).send(:define)
    end

    protected

    def initialize(software, software_filename)
      @software = software
      @software_filename = software_filename
    end

    attr_reader :software, :software_filename

    def define
      software.name "#{File.basename(software_filename)[0..-4]}"
      software.default_version gem_version

      # If the source directory for building stuff changes, tell omnibus to
      # de-cache us
      software.source path: File.expand_path("../..", __FILE__)

      # ruby and bundler and friends
      software.dependency "ruby"
      software.dependency "rubygems"

      gem_name = self.gem_name
      gem_version = self.gem_version
      gemspec = self.gemspec
      lockfile_path = self.lockfile_path

      software.build do
        extend BuildChefDKGem

        if gem_version == "<skip>"
          if gemspec
            block do
              log.info(log_key) { "#{gem_name} has source #{gemspec.source.name} in #{lockfile_path}. We only cache rubygems.org installs in omnibus to keep things simple. The chef-dk step will build #{gem_name} ..." }
            end
          else
            block do
              log.info(log_key) { "#{gem_name} is not in the #{lockfile_path}. This can happen if your OS doesn't build it, or if chef-dk no longer depends on it. Skipping ..." }
            end
          end
        else
          block do
            log.info(log_key) { "Found version #{gem_version} of #{gem_name} in #{lockfile_path}. Building early to take advantage of omnibus caching ..." }
          end
          gem "install #{gem_name} -v #{gem_version} --ignore-dependencies --verbose -- #{install_args_for(gem_name)}", env: env
        end
      end
    end

    # Path above omnibus (where Gemfile is)
    def root_path
      File.expand_path("../..", software.project.files_path)
    end

    def gemfile_path
      # gemfile path could be relative to software filename (and often is)
      @gemfile_path ||= File.join(root_path, "Gemfile")
    end

    def lockfile_path
      @lockfile_path ||= begin
        # Grab the version (and maybe source) from the lockfile so omnibus knows whether
        # to toss the cache or not
        lockfile_path = "#{gemfile_path}.#{Omnibus::Ohai["platform"]}.lock"
        unless File.exist?(lockfile_path)
          lockfile_path = "#{gemfile_path}.lock"
        end
        lockfile_path
      end
    end

    def gem_name
      @gem_name ||= begin
        # File must be named chef-dk-<gemname>.rb
        # Will look at chef-dk/Gemfile.lock and install that version of the gem using "gem install"
        # (and only that version)
        if File.basename(software_filename) =~ /^chef-dk-gem-(.+)\.rb$/
          $1
        else
          raise "#{software_filename} must be named chef-dk-<gemname>.rb to build a gem automatically"
        end
      end
    end

    def gemspec
      @gemspec ||= begin
        lockfile = Bundler::LockfileParser.new(IO.read(lockfile_path))
        gemspec = lockfile.specs.find { |s| s.name == gem_name }
        raise "#{gem_name} not found in #{lockfile_path}" unless gemspec
        gemspec
      end
    end

    def gem_version
      @gem_version ||= begin
        if gemspec && gemspec.source.name == "rubygems repository https://rubygems.org/"
          gemspec.version.to_s
        else
          "<skip>"
        end
      end
    end
  end
end
