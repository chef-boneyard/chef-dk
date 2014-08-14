
require 'chef-dk/exceptions'

require 'chef-dk/cookbook_profiler/null_scm'
require 'chef-dk/cookbook_profiler/git'

require 'chef-dk/cookbook_profiler/identifiers'
require 'chef-dk/policyfile/storage_config'

require 'chef-dk/policyfile/cookbook_location_specification'

module ChefDK
  module Policyfile

    # Base class for CookbookLock implementations
    class CookbookLock

      include Policyfile::StorageConfigDelegation

      # The cookbook name (without any version or other info suffixed)
      attr_reader :name

      # Options specifying the source and revision of this cookbook. These can
      # be passed to a CookbookLocationSpecification to create an object that can install the
      # same revision of the cookbook on another machine.
      attr_accessor :source_options

      # A string that uniquely identifies the cookbook version. If not
      # explicitly set, an identifier is generated based on the cookbook's
      # content.
      attr_accessor :identifier

      # A string in "X.Y.Z" version number format that uniquely identifies the
      # cookbook version. This is for compatibility with Chef Server 11.x,
      # where cookbooks are stored by x.y.z version numbers.
      attr_accessor :dotted_decimal_identifier

      attr_reader :storage_config

      attr_accessor :version

      def initialize(name, storage_config)
        @name = name
        @version = nil
        @source_options = nil
        @identifier = nil
        @dotted_decimal_identifier = nil
        @storage_config = storage_config
      end

      def install_locked
        cookbook_location_spec.ensure_cached
      end

      def cookbook_location_spec
        @location_spec ||= CookbookLocationSpecification.new(name, "= #{version}", source_options, storage_config)
      end

      def gather_profile_data
        @identifier ||= identifiers.content_identifier
        @dotted_decimal_identifier ||= identifiers.dotted_decimal_identifier
        @version ||= identifiers.semver_version
      end

      def identifiers
        @identifiers ||= CookbookProfiler::Identifiers.new(cookbook_version)
      end

      def cookbook_path
        raise NotImplementedError, "#{self.class} must override #to_lock with a specific implementation"
      end

      def to_lock
        raise NotImplementedError, "#{self.class} must override #to_lock with a specific implementation"
      end

      def build_from_lock_data(lock_data)
        raise NotImplementedError, "#{self.class} must override #build_from_lock_data with a specific implementation"
      end

      def validate!
        raise NotImplementedError, "#{self.class} must override #validate! with a specific implementation"
      end

      def refresh!
        raise NotImplementedError, "#{self.class} must override #refresh! with a specific implementation"
      end

      def updated?
        false
      end

      def identifier_updated?
        false
      end

      def version_updated?
        false
      end

      def symbolize_source_options_keys(source_options_from_json)
        source_options_from_json ||= {}
        source_options_from_json.inject({}) do |normalized_source_opts, (key, value)|
          normalized_source_opts[key.to_sym] = value
          normalized_source_opts
        end
      end

      def cookbook_version
        @cookbook_version ||= cookbook_loader.cookbook_version
      end

      def cookbook_loader
        @cookbook_loader ||=
          begin
            loader = Chef::Cookbook::CookbookVersionLoader.new(cookbook_path, chefignore)
            loader.load!
            loader
          end
      end

      def chefignore
        @chefignore ||= Chef::Cookbook::Chefignore.new(File.join(cookbook_path, "chefignore"))
      end
    end

    # CachedCookbook objects represent a cookbook that has been fetched from an
    # upstream canonical source and stored (presumed unmodified).
    class CachedCookbook < CookbookLock

      # The directory name in the cookbook cache where the cookbook is stored.
      # By convention, this should be the name of the cookbook followed by a
      # hyphen and then some sort of version identifier (depending on the
      # cookbook source).
      attr_accessor :cache_key

      # A URI pointing to the canonical source of the cookbook.
      attr_accessor :origin

      def initialize(name, storage_config)
        @name = name
        @version = nil
        @origin = nil
        @source_options = nil
        @cache_key = nil
        @identifier = nil
        @dotted_decimal_identifier = nil
        @storage_config = storage_config
      end

      def cookbook_path
        if cache_key.nil?
          raise MissingCookbookLockData, "Cannot locate cached cookbook `#{name}' because the `cache_key' attribute is not set"
        end
        File.join(cache_path, cache_key)
      end

      def build_from_lock_data(lock_data)
        @version = lock_data["version"]
        @identifier = lock_data["identifier"]
        @dotted_decimal_identifier = lock_data["dotted_decimal_identifier"]
        @cache_key = lock_data["cache_key"]
        @origin = lock_data["origin"]
        @source_options = symbolize_source_options_keys(lock_data["source_options"])
      end

      def to_lock
        validate!
        {
          "version" => version,
          "identifier" => identifier,
          "dotted_decimal_identifier" => dotted_decimal_identifier,
          "cache_key" => cache_key,
          "origin" => origin,
          "source_options" => source_options
        }
      end

      def validate!
        if cache_key.nil?
          raise CachedCookbookNotFound, "Cookbook `#{name}' does not have a `cache_key` set, cannot locate cookbook"
        end
        unless File.exist?(cookbook_path)
          raise CachedCookbookNotFound, "Cookbook `#{name}' not found at expected cache location `#{cache_key}' (full path: `#{cookbook_path}')"
        end
      end

      # Ignored. We do not expect the cookbook to get mutated
      # out-of-band, so refreshing the data should have no affect.
      # Mutating the cookbook is a validation error.
      def refresh!
      end

    end

    # LocalCookbook objects represent cookbooks that are sourced from the local
    # filesystem and are assumed to be under active development.
    class LocalCookbook < CookbookLock

      # A relative or absolute path to the cookbook. If a relative path is
      # given, it is resolved relative to #relative_paths_root
      attr_accessor :source

      def initialize(name, storage_config)
        @name = name
        @identifier = nil
        @storage_config = storage_config

        @identifier_updated = false
        @version_updated = false
      end

      def cookbook_path
        File.expand_path(source, relative_paths_root)
      end

      def scm_profiler
        if File.exist?(File.join(cookbook_path, ".git"))
          CookbookProfiler::Git.new(cookbook_path)
        else
          CookbookProfiler::NullSCM.new(cookbook_path)
        end
      end

      def scm_info
        scm_profiler.profile_data
      end

      def to_lock
        validate!
        {
          "version" => version,
          "identifier" => identifier,
          "dotted_decimal_identifier" => dotted_decimal_identifier,
          "source" => source,
          "cache_key" => nil,
          "scm_info" => scm_info,
          "source_options" => source_options
        }
      end

      def build_from_lock_data(lock_data)
        @version = lock_data["version"]
        @identifier = lock_data["identifier"]
        @dotted_decimal_identifier = lock_data["dotted_decimal_identifier"]
        @source = lock_data["source"]
        @source_options = symbolize_source_options_keys(lock_data["source_options"])
      end

      def validate!
        if source.nil?
          raise LocalCookbookNotFound, "Cookbook `#{name}' does not have a `source` set, cannot locate cookbook"
        end
        unless File.exist?(cookbook_path)
          raise LocalCookbookNotFound, "Cookbook `#{name}' not found at path source `#{source}` (full path: `#{cookbook_path}')"
        end
        unless cookbook_version.name.to_s == name
          msg = "The cookbook at path source `#{source}' is expected to be named `#{name}', but is now named `#{cookbook_version.name}' (full path: #{cookbook_path})"
          raise MalformedCookbook, msg
        end
      end

      def refresh!
        old_identifier, old_version = @identifier, @version
        @identifier, @dotted_decimal_identifier, @version = nil, nil, nil
        gather_profile_data
        if @identifier != old_identifier
          @identifier_updated = true
        end
        if @version != old_version
          @version_updated = true
        end
        self
      end

      def updated?
        @identifier_updated || @version_updated
      end

      def version_updated?
        @version_updated
      end

      def identifier_updated?
        @identifier_updated
      end

    end
  end
end
