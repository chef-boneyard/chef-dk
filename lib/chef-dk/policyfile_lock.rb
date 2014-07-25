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

require 'chef-dk/policyfile/storage_config'
require 'chef-dk/policyfile/cookbook_locks'

module ChefDK
  class PolicyfileLock


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
      cached_cookbook = Policyfile::CachedCookbook.new(name, storage_config)
      yield cached_cookbook if block_given?
      @cookbook_locks[name] = cached_cookbook
    end

    def local_cookbook(name)
      local_cookbook = Policyfile::LocalCookbook.new(name, storage_config)
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
      cookbook_locks.inject({}) do |locks_map, (name, location_spec)|
        location_spec.validate!
        location_spec.gather_profile_data
        locks_map[name] = location_spec.to_lock
        locks_map
      end
    end

    # TODO: this needs to iterate over the cookbooks and make sure the computed
    # IDs haven't changed. If the source is `:path` and the ID has changed,
    # then we should rebuild the lockfile (perhaps with an option to *not* do
    # this?). However, if the cookbook's dependencies have changed, then we at
    # minimum have to verify that the solution is still valid, or force the
    # user to recompile.
    def validate_cookbooks!
      raise "TODO: IMPLEMENT ME" unless $hax_mode
      true
    end

    def build_from_compiler(compiler)
      @name = compiler.name

      @run_list = compiler.normalized_run_list

      compiler.all_cookbook_location_specs.each do |cookbook_name, spec|
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

    def install_cookbooks
      # note: duplicates PolicyfileCompiler#ensure_cache_dir_exists
      ensure_cache_dir_exists

      cookbook_locks.each do |cookbook_name, cookbook_lock|
        cookbook_lock.install_locked
      end
    end

    def ensure_cache_dir_exists
      # note: duplicates PolicyfileCompiler#ensure_cache_dir_exists
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
