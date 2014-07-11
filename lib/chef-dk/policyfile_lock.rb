#
# Copyright:: Copyright (c) 2014 Chef Software Inc.
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

require 'chef-dk/cookbook_profiler/identifiers'
require 'chef-dk/cookbook_profiler/null_scm'
require 'chef-dk/cookbook_profiler/git'
require 'chef-dk/policyfile/storage_config'

# TODO: reconsider how this dependency is used here.
require 'chef-dk/cookbook_omnifetch'
# TODO: fix this dependency via refactor
require 'semverse'

module ChefDK
  class PolicyfileLock

    # CachedCookbook objects represent a cookbook that has been fetched from an
    # upstream canonical source and stored (presumed unmodified).
    # --
    # TODO: lots of duplication between these classes and CookbookSpec.
    class CachedCookbook

      include Policyfile::StorageConfigDelegation

      # The cookbook name (without any version or other info suffixed)
      attr_reader :name

      # The directory name in the cookbook cache where the cookbook is stored.
      # By convention, this should be the name of the cookbook followed by a
      # hyphen and then some sort of version identifier (depending on the
      # cookbook source).
      attr_accessor :cache_key

      # A URI pointing to the canonical source of the cookbook.
      attr_accessor :origin

      # Options specifying the source and revision of this cookbook. These can
      # be passed to a CookbookSpec to create an object that can install the
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
        @origin = nil
        @source_options = nil
        @cache_key = nil
        @identifier = nil
        @dotted_decimal_identifier = nil
        @storage_config = storage_config
      end

      def cookbook_path
        File.join(cache_path, cache_key)
      end

      # TODO: duplicates CookbookSpec#initialize
      def version_constraint
        Semverse::Constraint.new("= #{version}")
      end


      # TODO: duplicates CookbookSpec#ensure_cached
      def install_locked
        unless installer.installed?
          installer.install
        end
      end

      # TODO: validate source options
      def installer
        @installer ||= CookbookOmnifetch.init(self, source_options)
      end

      def gather_profile_data
        @identifier ||= identifiers.content_identifier
        @dotted_decimal_identifier ||= identifiers.dotted_decimal_identifier
        @version ||= identifiers.semver_version
      end

      def build_from_lock_data(lock_data)
        @version = lock_data["version"]
        @identifier = lock_data["identifier"]
        @dotted_decimal_identifier = lock_data["dotted_decimal_identifier"]
        @cache_key = lock_data["cache_key"]
        @origin = lock_data["origin"]
        # TODO: test
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

      def identifiers
        @identifiers ||= CookbookProfiler::Identifiers.new(cookbook_path)
      end

      def validate!
        if cache_key.nil?
          raise CachedCookbookNotFound, "Cookbook `#{name}' does not have a `cache_key` set, cannot locate cookbook"
        end
        unless File.exist?(cookbook_path)
          raise CachedCookbookNotFound, "Cookbook `#{name}' not found at expected cache location `#{cache_key}' (full path: `#{cookbook_path}')"
        end
      end

      private

      def symbolize_source_options_keys(source_options_from_json)
        source_options_from_json ||= {}
        source_options_from_json.inject({}) do |normalized_source_opts, (key, value)|
          normalized_source_opts[key.to_sym] = value
          normalized_source_opts
        end
      end

    end

    # LocalCookbook objects represent cookbooks that are sourced from the local
    # filesystem and are assumed to be under active development.
    class LocalCookbook

      include Policyfile::StorageConfigDelegation

      # The cookbook name (without any version or other info suffixed)
      attr_reader :name

      # A relative or absolute path to the cookbook. If a relative path is
      # given, it is resolved relative to #relative_paths_root
      attr_accessor :source

      # Options specifying the source and revision of this cookbook. These can
      # be passed to a CookbookSpec to create an object that can install the
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

      attr_accessor :version

      attr_reader :storage_config

      def initialize(name, storage_config)
        @name = name
        @identifier = nil
        @storage_config = storage_config
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

      # TODO: duplicates CookbookSpec#initialize
      def version_constraint
        Semverse::Constraint.new("= #{version}")
      end

      # TODO: duplicates CookbookSpec#ensure_cached
      def install_locked
        unless installer.installed?
          installer.install
        end
      end

      # TODO: validate source options
      def installer
        @installer ||= CookbookOmnifetch.init(self, source_options)
      end

      def gather_profile_data
        @identifier ||= identifiers.content_identifier
        @dotted_decimal_identifier ||= identifiers.dotted_decimal_identifier
        @version ||= identifiers.semver_version
      end

      def to_lock
        validate!
        {
          "version" => version,
          "identifier" => identifier,
          "dotted_decimal_identifier" => dotted_decimal_identifier,
          "source" => source,
          "cache_key" => nil,
          "scm_info" => scm_profiler.profile_data,
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

      def identifiers
        @identifiers ||= CookbookProfiler::Identifiers.new(cookbook_path)
      end

      def validate!
        if source.nil?
          raise CachedCookbookNotFound, "Cookbook `#{name}' does not have a `source` set, cannot locate cookbook"
        end
        unless File.exist?(cookbook_path)
          raise CachedCookbookNotFound, "Cookbook `#{name}' not found at path source `#{source}` (full path: `#{cookbook_path}')"
        end
      end

      private

      # TODO: duplicates CachedCookbook#symbolize_source_options_keys
      def symbolize_source_options_keys(source_options_from_json)
        source_options_from_json ||= {}
        source_options_from_json.inject({}) do |normalized_source_opts, (key, value)|
          normalized_source_opts[key.to_sym] = value
          normalized_source_opts
        end
      end

    end

    def self.build(storage_config)
      lock = new(storage_config)
      yield lock
      lock
    end

    def self.build_from_compiler(compiler, storage_config)
      lock = new(storage_config)
      lock.build_from_compiler(compiler)
      lock
    end

    include Policyfile::StorageConfigDelegation

    attr_accessor :name
    attr_accessor :run_list
    attr_reader :storage_config

    attr_reader :cookbook_locks

    def initialize(storage_config)
      @name = nil
      @run_list = []
      @cookbook_locks = {}
      @relative_paths_root = Dir.pwd
      @storage_config = storage_config
    end

    def cached_cookbook(name)
      cached_cookbook = CachedCookbook.new(name, storage_config)
      yield cached_cookbook if block_given?
      @cookbook_locks[name] = cached_cookbook
    end

    def local_cookbook(name)
      local_cookbook = LocalCookbook.new(name, storage_config)
      yield local_cookbook if block_given?
      @cookbook_locks[name] = local_cookbook
    end

    def to_lock
      {}.tap do |lock|
        lock["name"] = name
        lock["run_list"] = run_list
        lock["cookbook_locks"] = cookbook_locks_for_lockfile
      end
    end

    def cookbook_locks_for_lockfile
      cookbook_locks.inject({}) do |locks_map, (name, cookbook_spec)|
        cookbook_spec.validate!
        cookbook_spec.gather_profile_data
        locks_map[name] = cookbook_spec.to_lock
        locks_map
      end
    end

    def build_from_compiler(compiler)
      @name = compiler.name
      @run_list = compiler.expanded_run_list

      compiler.all_cookbook_specs.each do |cookbook_name, spec|
        if spec.mirrors_canonical_upstream?
          cached_cookbook(cookbook_name) do |cached_cb|
            cached_cb.cache_key = spec.cache_key
            cached_cb.origin = spec.uri
            cached_cb.source_options = spec.source_options_for_lock
          end
        else
          local_cookbook(cookbook_name) do |local_cb|
            local_cb.source = spec.relative_path
            local_cb.source_options = spec.source_options_for_lock
          end
        end
      end
      self
    end

    def build_from_lock_data(lock_data)
      self.name = lock_data["name"]
      self.run_list = lock_data["run_list"]
      lock_data["cookbook_locks"].each do |name, lock_info|
        build_cookbook_lock_from_lock_data(name, lock_info)
      end
      self
    end

    # TODO: duplicates PolicyfileCompiler#install
    def install_cookbooks
      ensure_cache_dir_exists

      cookbook_locks.each do |cookbook_name, cookbook_lock|
        cookbook_lock.install_locked
      end
    end

    # TODO: duplicates PolicyfileCompiler#ensure_cache_dir_exists
    def ensure_cache_dir_exists
      unless File.exist?(cache_path)
        FileUtils.mkdir_p(cache_path)
      end
    end

    private

    def build_cookbook_lock_from_lock_data(name, lock_info)
      if lock_info["cache_key"].nil?
        local_cookbook(name).build_from_lock_data(lock_info)
      else
        cached_cookbook(name).build_from_lock_data(lock_info)
      end
    end

  end
end
