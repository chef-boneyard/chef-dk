require "bundler"
require "omnibus"
require_relative "../build-chef-dk-gem"
require_relative "../../../../tasks/gemfile_util"

module BuildChefDKGem
  class GemInstallSoftwareDef
    def self.define(software, software_filename)
      new(software, software_filename).send(:define)
    end

    include BuildChefDKGem
    include Omnibus::Logging

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
      gem_metadata = self.gem_metadata
      lockfile_path = self.lockfile_path

      software.build do
        extend BuildChefDKGem

        if gem_version == "<skip>"
          if gem_metadata
            block do
              log.info(log_key) { "#{gem_name} has source #{gem_metadata} in #{lockfile_path}. We only cache rubygems.org installs in omnibus to keep things simple. The chef-dk step will build #{gem_name} ..." }
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
          gem "install #{gem_name} -v #{gem_version} --no-doc --no-ri --ignore-dependencies --verbose -- #{install_args_for(gem_name)}", env: env
        end
      end
    end

    # Path above omnibus (where Gemfile is)
    def root_path
      File.expand_path("../../../../..", __FILE__)
    end

    def gemfile_path
      File.join(root_path, "Gemfile")
    end

    def lockfile_path
      "#{gemfile_path}.lock"
    end

    def gem_name
      @gem_name ||= begin
        # File must be named chef-<gemname>.rb
        # Will look at chef/Gemfile.lock and install that version of the gem using "gem install"
        # (and only that version)
        if File.basename(software_filename) =~ /^chef-dk-gem-(.+)\.rb$/
          $1
        else
          raise "#{software_filename} must be named chef-<gemname>.rb to build a gem automatically"
        end
      end
    end

    def gem_metadata
      @gem_metadata ||= begin
        bundle = GemfileUtil::Bundle.parse(gemfile_path, lockfile_path)
        result = bundle.gems[gem_name]
        if result
          if bundle.select_gems(without_groups: without_groups).include?(gem_name)
            log.info(software.name) { "Using #{gem_name} version #{result[:version]} from #{gemfile_path}" }
            result
          else
            log.info(software.name) { "#{gem_name} not loaded from #{gemfile_path} because it was only in groups #{without_groups.join(", ")}. Skipping ..." }
            nil
          end
        else
          log.info(software.name) { "#{gem_name} was not found in #{lockfile_path}. Skipping ..." }
          nil
        end
      end
    end

    def gem_version
      @gem_version ||= begin
        if gem_metadata && URI(gem_metadata[:source]) == URI("https://rubygems.org/")
          gem_metadata[:version]
        else
          "<skip>"
        end
      end
    end
  end
end
