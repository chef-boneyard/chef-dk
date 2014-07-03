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

module ChefDK
  class PolicyfileLock

    # CachedCookbook objects represent a cookbook that has been fetched from an
    # upstream canonical source and stored (presumed unmodified).
    class CachedCookbook

      # The cookbook name (without any version or other info suffixed)
      attr_reader :name

      # The directory name in the cookbook cache where the cookbook is stored.
      # By convention, this should be the name of the cookbook followed by a
      # hyphen and then some sort of version identifier (depending on the
      # cookbook source).
      attr_accessor :cache_key

      # A URI pointing to the canonical source of the cookbook.
      attr_accessor :origin

      # A string that uniquely identifies the cookbook version. If not
      # explicitly set, an identifier is generated based on the cookbook's
      # content.
      attr_writer :identifier

      # A string in "X.Y.Z" version number format that uniquely identifies the
      # cookbook version. This is for compatibility with Chef Server 11.x,
      # where cookbooks are stored by x.y.z version numbers.
      attr_writer :dotted_decimal_identifier

      # The root of the cookbook cache.
      attr_reader :cache_path

      def initialize(name, cache_path)
        @name = name
        @cache_path = cache_path
        @origin = nil
        @cache_key = nil
        @identifier = nil
        @dotted_decimal_identifier = nil
      end

      def cookbook_path
        File.join(cache_path, cache_key)
      end

      def identifier
        @identifier || identifiers.content_identifier
      end

      def dotted_decimal_identifier
        @dotted_decimal_identifier || identifiers.dotted_decimal_identifier
      end

      def to_lock
        validate!
        {
          "version" => identifiers.semver_version,
          "identifier" => identifier,
          "dotted_decimal_identifier" => dotted_decimal_identifier,
          "cache_key" => cache_key,
          "origin" => origin
        }
      end

      def identifiers
        @identifiers ||= CookbookProfiler::Identifiers.new(cookbook_path)
      end

      def validate!
        unless File.exist?(cookbook_path)
          raise CachedCookbookNotFound, "Cookbook `#{name}' not found at expected cache location `#{cookbook_path}'"
        end
      end

    end

    # LocalCookbook objects represent cookbooks that are sourced from the local
    # filesystem and are assumed to be under active development.
    class LocalCookbook

      # A relative or absolute path to the cookbook. If a relative path is
      # given, it is resolved relative to #relative_paths_root
      attr_accessor :source

      # A string that uniquely identifies the cookbook version. If not
      # explicitly set, an identifier is generated based on the cookbook's
      # content.
      attr_writer :identifier

      # A string in "X.Y.Z" version number format that uniquely identifies the
      # cookbook version. This is for compatibility with Chef Server 11.x,
      # where cookbooks are stored by x.y.z version numbers.
      attr_writer :dotted_decimal_identifier

      # The root path from which source is expanded.
      attr_accessor :relative_paths_root

      def initialize(name, relative_paths_root)
        @name = name
        @identifier = nil
        @relative_paths_root = relative_paths_root
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

      def identifier
        @identifier || identifiers.content_identifier
      end

      def dotted_decimal_identifier
        @dotted_decimal_identifier || identifiers.dotted_decimal_identifier
      end

      def to_lock

        {
          "version" => identifiers.semver_version,
          "identifier" => identifier,
          "dotted_decimal_identifier" => dotted_decimal_identifier,
          "source" => source,
          "cache_key" => nil,
          "scm_info" => scm_profiler.profile_data
        }
      end

      def identifiers
        @identifiers ||= CookbookProfiler::Identifiers.new(cookbook_path)
      end

    end

    def self.build(options = {})
      lock = new(options)
      yield lock
      lock
    end

    def self.build_from_compiler(compiler, options = {})
      lock = new(options)
      lock.build_from_compiler(compiler)
      lock
    end

    attr_accessor :name
    attr_accessor :run_list

    attr_reader :cookbook_locks
    attr_reader :cache_path
    attr_reader :relative_paths_root

    def initialize(options = {})
      @name = nil
      @run_list = []
      @cookbook_locks = {}
      @relative_paths_root = Dir.pwd
      handle_options(options)
    end

    def cached_cookbook(name)
      cached_cookbook = CachedCookbook.new(name, cache_path)
      yield cached_cookbook
      @cookbook_locks[name] = cached_cookbook
    end

    def local_cookbook(name)
      local_cookbook = LocalCookbook.new(name, relative_paths_root)
      yield local_cookbook
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
        locks_map[name] = cookbook_spec.to_lock
        locks_map
      end
    end

    def build_from_compiler(compiler)
      @run_list = compiler.expanded_run_list

      compiler.all_cookbook_specs.each do |cookbook_name, spec|
        if spec.mirrors_canonical_upstream?
          cached_cookbook(cookbook_name) do |cached_cb|
            cached_cb.cache_key = spec.cache_key
            cached_cb.origin = spec.uri
          end
        else
          local_cookbook(cookbook_name) do |local_cb|
            local_cb.source = spec.relative_path
            local_cb.relative_paths_root = spec.relative_paths_root
          end
        end
      end
      self
    end

    private

    def handle_options(options)
      @cache_path = options[:cache_path]
      @relative_paths_root = options[:relative_paths_root] if options.key?(:relative_paths_root)
    end
  end
end
