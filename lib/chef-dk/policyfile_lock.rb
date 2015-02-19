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

require 'digest/sha1'

require 'chef-dk/policyfile/storage_config'
require 'chef-dk/policyfile/cookbook_locks'
require 'chef-dk/policyfile/solution_dependencies'
require 'chef-dk/ui'

module ChefDK

  class PolicyfileLock

    class InstallReport

      attr_reader :ui
      attr_reader :policyfile_lock

      def initialize(ui: ui, policyfile_lock: nil)
        @ui = ui
        @policyfile_lock = policyfile_lock

        @cookbook_name_width = nil
        @cookbook_version_width = nil
      end

      def installing_fixed_version_cookbook(cookbook_spec)
        verb = cookbook_spec.installed? ? "Using     " : "Installing"
        ui.msg("#{verb} #{format_fixed_version_cookbook(cookbook_spec)}")
      end

      def installing_cookbook(cookbook_lock)
        verb = cookbook_lock.installed? ? "Using     " : "Installing"
        ui.msg("#{verb} #{format_cookbook(cookbook_lock)}")
      end

      private

      def format_cookbook(cookbook_lock)
        "#{cookbook_lock.name.ljust(cookbook_name_width)} #{cookbook_lock.version.to_s.ljust(cookbook_version_width)}"
      end

      def cookbook_name_width
        policyfile_lock.cookbook_locks.map { |name, _| name.size }.max
      end

      def cookbook_version_width
        policyfile_lock.cookbook_locks.map { |_, lock| lock.version.size }.max
      end
    end

    RUN_LIST_ITEM_FORMAT = /\Arecipe\[[^\s]+::[^\s]+\]\Z/.freeze

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
    attr_accessor :named_run_lists

    attr_reader :solution_dependencies

    attr_reader :storage_config

    attr_reader :cookbook_locks

    attr_reader :install_report

    def initialize(storage_config, ui: nil)
      @name = nil
      @run_list = []
      @named_run_lists = {}
      @cookbook_locks = {}
      @relative_paths_root = Dir.pwd
      @storage_config = storage_config
      @ui = ui || UI.null

      @solution_dependencies = Policyfile::SolutionDependencies.new
      @install_report = InstallReport.new(ui: @ui, policyfile_lock: self)
    end

    def lock_data_for(cookbook_name)
      @cookbook_locks[cookbook_name]
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

    def dependencies
      yield solution_dependencies
    end

    def to_lock
      {}.tap do |lock|
        lock["name"] = name
        lock["run_list"] = run_list
        lock["named_run_lists"] = named_run_lists unless named_run_lists.empty?
        lock["cookbook_locks"] = cookbook_locks_for_lockfile
        lock["solution_dependencies"] = solution_dependencies.to_lock
      end
    end

    # Returns a fingerprint of the PolicyfileLock by computing the SHA1 hash of
    # #canonical_revision_string
    def revision_id
      Digest::SHA1.new.hexdigest(canonical_revision_string)
    end

    # Generates a string representation of the lock data in a specialized
    # format suitable for generating a checksum of the lock itself. Only data
    # that modifies the behavior of a chef-client using the lockfile is
    # included in this format; for example, a modification to the source
    # options in a `Policyfile.rb` that yields identical code (such as
    # switching to a github fork at the same revision) will not cause a change
    # in the PolicyfileLock's canonical_revision_string.
    #
    # This format is intended to be used only for generating an identifier for
    # a particular revision of a PolicyfileLock. It should not be used as a
    # serialization format, and is not guaranteed to be a stable interface.
    def canonical_revision_string
      canonical_rev_text = ""

      canonical_rev_text << "name:#{name}\n"

      run_list.each do |item|
        canonical_rev_text << "run-list-item:#{item}\n"
      end

      named_run_lists.each do |name, run_list|
        run_list.each do |item|
          canonical_rev_text << "named-run-list:#{name};run-list-item:#{item}\n"
        end
      end

      cookbook_locks_for_lockfile.each do |name, lock|
        canonical_rev_text << "cookbook:#{name};id:#{lock["identifier"]}\n"
      end

      canonical_rev_text
    end

    def cookbook_locks_for_lockfile
      cookbook_locks.inject({}) do |locks_map, (name, location_spec)|
        location_spec.validate!
        location_spec.gather_profile_data
        locks_map[name] = location_spec.to_lock
        locks_map
      end
    end

    def validate_cookbooks!
      cookbook_locks.each do |name, cookbook_lock|
        cookbook_lock.validate!
        cookbook_lock.refresh!
      end

      # Check that versions and dependencies are still valid. First we need to
      # refresh the dependency info for everything that has changed, then we
      # check that the new versions and dependencies are valid for the working
      # set of cookbooks. We can't do this in a single loop because the user
      # may have modified two cookbooks such that the versions and constraints
      # are only valid when both changes are considered together.
      cookbook_locks.each do |name, cookbook_lock|
        if cookbook_lock.updated?
          solution_dependencies.update_cookbook_dep(name, cookbook_lock.version, cookbook_lock.dependencies)
        end
      end
      cookbook_locks.each do |name, cookbook_lock|
        if cookbook_lock.updated?
          solution_dependencies.test_conflict!(cookbook_lock.name, cookbook_lock.version)
        end
      end

      true
    end

    def build_from_compiler(compiler)
      @name = compiler.name

      @run_list = compiler.normalized_run_list

      @named_run_lists = compiler.normalized_named_run_lists

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

      @solution_dependencies = compiler.solution_dependencies

      self
    end

    def build_from_lock_data(lock_data)
      set_name_from_lock_data(lock_data)
      set_run_list_from_lock_data(lock_data)
      set_cookbook_locks_from_lock_data(lock_data)
      set_solution_dependencies_from_lock_data(lock_data)
      self
    end

    def install_cookbooks
      # note: duplicates PolicyfileCompiler#ensure_cache_dir_exists
      ensure_cache_dir_exists

      cookbook_locks.each do |cookbook_name, cookbook_lock|
        install_report.installing_cookbook(cookbook_lock)
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

    def set_name_from_lock_data(lock_data)
      name_attribute = lock_data["name"]

      raise InvalidLockfile, "lockfile does not have a `name' attribute" if name_attribute.nil?

      unless name_attribute.kind_of?(String)
        raise InvalidLockfile, "lockfile's name attribute must be a String (got: #{name_attribute.inspect})"
      end

      if name_attribute.empty?
        raise InvalidLockfile, "lockfile's name attribute cannot be an empty string"
      end

      @name = name_attribute

    end

    def set_run_list_from_lock_data(lock_data)
      run_list_attribute = lock_data["run_list"]

      raise InvalidLockfile, "lockfile does not have a run_list attribute" if run_list_attribute.nil?

      unless run_list_attribute.kind_of?(Array)
        raise InvalidLockfile, "lockfile's run_list must be an array of run list items (got: #{run_list_attribute.inspect})"
      end

      bad_run_list_items = run_list_attribute.select { |e| e !~ RUN_LIST_ITEM_FORMAT }

      unless bad_run_list_items.empty?
        msg = "lockfile's run_list items must be formatted like `recipe[$COOKBOOK_NAME::$RECIPE_NAME]'. Invalid items: `#{bad_run_list_items.join("' `")}'"
        raise InvalidLockfile, msg
      end

      @run_list = run_list_attribute
    end

    def set_cookbook_locks_from_lock_data(lock_data)
      cookbook_lock_data = lock_data["cookbook_locks"]

      if cookbook_lock_data.nil?
        raise InvalidLockfile, "lockfile does not have a cookbook_locks attribute"
      end

      unless cookbook_lock_data.kind_of?(Hash)
        raise InvalidLockfile, "lockfile's cookbook_locks attribute must be a Hash (JSON object). (got: #{cookbook_lock_data.inspect})"
      end

      lock_data["cookbook_locks"].each do |name, lock_info|
        build_cookbook_lock_from_lock_data(name, lock_info)
      end
    end

    def set_solution_dependencies_from_lock_data(lock_data)
      soln_deps = lock_data["solution_dependencies"]

      if soln_deps.nil?
        raise InvalidLockfile, "lockfile does not have a solution_dependencies attribute"
      end

      unless soln_deps.kind_of?(Hash)
        raise InvalidLockfile, "lockfile's solution_dependencies attribute must be a Hash (JSON object). (got: #{soln_deps.inspect})"
      end

      s = Policyfile::SolutionDependencies.from_lock(lock_data["solution_dependencies"])
      @solution_dependencies = s
    end

    def build_cookbook_lock_from_lock_data(name, lock_info)
      unless lock_info.kind_of?(Hash)
        raise InvalidLockfile, "lockfile cookbook_locks entries must be a Hash (JSON object). (got: #{lock_info.inspect})"
      end

      if lock_info["cache_key"].nil?
        local_cookbook(name).build_from_lock_data(lock_info)
      else
        cached_cookbook(name).build_from_lock_data(lock_info)
      end
    end

  end
end
