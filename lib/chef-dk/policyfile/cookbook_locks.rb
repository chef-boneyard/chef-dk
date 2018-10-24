#
# Copyright:: Copyright (c) 2014-2018 Chef Software Inc.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require "forwardable"

require "chef-dk/exceptions"

require "chef-dk/cookbook_profiler/null_scm"
require "chef-dk/cookbook_profiler/git"

require "chef-dk/cookbook_profiler/identifiers"
require "chef-dk/policyfile/storage_config"

require "chef-dk/policyfile/cookbook_location_specification"

module ChefDK

  module Policyfile

    # Base class for CookbookLock implementations
    class CookbookLock

      REQUIRED_LOCK_DATA_KEYS = %w{version identifier dotted_decimal_identifier cache_key source_options}.freeze
      REQUIRED_LOCK_DATA_KEYS.each(&:freeze)
      REQUIRED_LOCK_DATA_KEYS.freeze

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

      def installed?
        cookbook_location_spec.installed?
      end

      def install_locked
        cookbook_location_spec.ensure_cached
      end

      def cookbook_location_spec
        raise InvalidCookbookLockData, "Cannot create CookbookLocationSpecification for #{name} without version" if version.nil?
        raise InvalidCookbookLockData, "Cannot create CookbookLocationSpecification for #{name} without source options" if source_options.nil?
        @location_spec ||= CookbookLocationSpecification.new(name, "= #{version}", source_options, storage_config)
      end

      def dependencies
        cookbook_location_spec.dependencies
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
        raise NotImplementedError, "#{self.class} must override #cookbook_path with a specific implementation"
      end

      def to_lock
        validate!
        lock_data
      end

      def lock_data
        raise NotImplementedError, "#{self.class} must override #lock_data a specific implementation"
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

      private

      def assert_required_keys_valid!(lock_data)
        missing_keys = REQUIRED_LOCK_DATA_KEYS.reject { |key| lock_data.key?(key) }
        unless missing_keys.empty?
          raise InvalidLockfile, "Lockfile cookbook_lock for #{name} missing required attributes `#{missing_keys.join("', `")}'"
        end

        version = lock_data["version"]
        unless version.kind_of?(String)
          raise InvalidLockfile, "Lockfile cookbook_lock for #{name} `version' attribute must be a string (got: #{version})"
        end

        identifier = lock_data["identifier"]
        unless identifier.kind_of?(String)
          raise InvalidLockfile, "Lockfile cookbook_lock for #{name} `identifier' attribute must be a string (got: #{identifier})"
        end

        cache_key = lock_data["cache_key"]
        unless cache_key.kind_of?(String) || cache_key.nil?
          raise InvalidLockfile, "Lockfile cookbook_lock for #{name} `cache_key' attribute must be a string (got: #{cache_key})"
        end

        source_options = lock_data["source_options"]
        unless source_options.kind_of?(Hash)
          raise InvalidLockfile, "Lockfile cookbook_lock for #{name} `source_options' attribute must be a Hash (JSON object) (got: #{source_options})"
        end
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
        assert_required_keys_valid!(lock_data)

        @version = lock_data["version"]
        @identifier = lock_data["identifier"]
        @dotted_decimal_identifier = lock_data["dotted_decimal_identifier"]
        @cache_key = lock_data["cache_key"]
        @origin = lock_data["origin"]
        @source_options = symbolize_source_options_keys(lock_data["source_options"])
      end

      def lock_data
        {
          "version" => version,
          "identifier" => identifier,
          "dotted_decimal_identifier" => dotted_decimal_identifier,
          "cache_key" => cache_key,
          "origin" => origin,
          "source_options" => source_options,
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

      # We do not expect the cookbook to get mutated out-of-band, so refreshing
      # the data generally should have no affect. If the cookbook has been
      # mutated, though, then a CachedCookbookModified exception is raised.
      def refresh!
        # This behavior fits better with the intent of the #validate! method,
        # but we cannot check for modifications there because the user may be
        # setting custom identifiers.
        if @identifier && identifiers.content_identifier != @identifier
          message = "Cached cookbook `#{name}' (#{version}) has been modified since the lockfile was generated. " +
            "Cached cookbooks cannot be modified. (full path: `#{cookbook_path}')"
          raise CachedCookbookModified, message
        end
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
        @cookbook_in_git_repo = nil
        @scm_info = nil
      end

      def cookbook_path
        File.expand_path(source, relative_paths_root)
      end

      def scm_profiler
        if cookbook_in_git_repo?
          CookbookProfiler::Git.new(cookbook_path)
        else
          CookbookProfiler::NullSCM.new(cookbook_path)
        end
      end

      def scm_info
        @scm_info
      end

      def to_lock
        refresh_scm_info
        super
      end

      def lock_data
        {
          "version" => version,
          "identifier" => identifier,
          "dotted_decimal_identifier" => dotted_decimal_identifier,
          "source" => source,
          "cache_key" => nil,
          "scm_info" => scm_info,
          "source_options" => source_options,
        }
      end

      def build_from_lock_data(lock_data)
        assert_required_keys_valid!(lock_data)

        @version = lock_data["version"]
        @identifier = lock_data["identifier"]
        @dotted_decimal_identifier = lock_data["dotted_decimal_identifier"]
        @source = lock_data["source"]
        @source_options = symbolize_source_options_keys(lock_data["source_options"])
        @scm_info = lock_data["scm_info"]
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

      private

      def refresh_scm_info
        @scm_info = scm_profiler.profile_data
      end

      def assert_required_keys_valid!(lock_data)
        super

        source = lock_data["source"]
        if source.nil?
          raise InvalidLockfile, "Lockfile cookbook_lock for #{name} is invalid. Lock data for a local cookbook must have a `source' attribute"
        end

        unless source.kind_of?(String)
          raise InvalidLockfile, "Lockfile cookbook_lock for #{name} is invalid: `source' attribute must be a String (got: #{source.inspect})"
        end
      end

      def cookbook_in_git_repo?
        return @cookbook_in_git_repo unless @cookbook_in_git_repo.nil?

        @cookbook_in_git_repo = false

        dot_git = Pathname.new(".git")
        Pathname.new(cookbook_path).ascend do |parent_dir|
          possbile_git_dir = parent_dir + dot_git
          if possbile_git_dir.exist?
            @cookbook_in_git_repo = true
            break
          end
        end

        @cookbook_in_git_repo
      end

    end

    class ArchivedCookbook < CookbookLock

      extend Forwardable

      def_delegator :@archived_lock, :name
      def_delegator :@archived_lock, :source_options
      def_delegator :@archived_lock, :identifier
      def_delegator :@archived_lock, :dotted_decimal_identifier
      def_delegator :@archived_lock, :version
      def_delegator :@archived_lock, :source

      # #to_lock calls #validate! which will typically ensure that the cookbook
      # is present at the correct path for the lock type. For an archived
      # cookbook, the cookbook is located in the archive, so it probably won't
      # exist there. Therefore, we bypass #validate! and get the lock data
      # directly.
      def_delegator :@archived_lock, :lock_data, :to_lock

      def initialize(archived_lock, storage_config)
        @archived_lock = archived_lock
        @storage_config = storage_config
      end

      def build_from_lock_data(lock_data)
        raise NotImplementedError, "ArchivedCookbook cannot be built from lock data, it can only wrap an existing lock object"
      end

      def installed?
        File.exist?(cookbook_path) && File.directory?(cookbook_path)
      end

      # The cookbook is assumed to be stored in a Chef Zero compatible repo as
      # created by `chef export`. Currently that only creates "compatibility
      # mode" repos since Chef Zero doesn't yet support cookbook_artifact APIs.
      # So the cookbook will be located in a path like:
      #   cookbooks/nginx-111.222.333
      def cookbook_path
        File.join(relative_paths_root, "cookbook_artifacts", "#{name}-#{identifier}")
      end

      # We trust that archived cookbooks haven't been modified, so just return
      # true for #validate!
      def validate!
        true
      end

      # We trust that archived cookbooks haven't been modified, so just return
      # true for #refresh!
      def refresh!
        true
      end
    end

  end
end
