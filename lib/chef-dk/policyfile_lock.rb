# -*- coding: UTF-8 -*-
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

require "digest/sha2"

require "chef-dk/policyfile/storage_config"
require "chef-dk/policyfile/cookbook_locks"
require "chef-dk/policyfile/solution_dependencies"
require "chef-dk/ui"

module ChefDK

  class PolicyfileLock

    class InstallReport

      attr_reader :ui
      attr_reader :policyfile_lock

      def initialize(ui: nil, policyfile_lock: nil)
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
    attr_accessor :default_attributes
    attr_accessor :override_attributes

    attr_reader :solution_dependencies

    attr_reader :storage_config

    attr_reader :cookbook_locks

    attr_reader :included_policy_locks

    attr_reader :install_report

    def initialize(storage_config, ui: nil)
      @name = nil
      @run_list = []
      @named_run_lists = {}
      @cookbook_locks = {}
      @relative_paths_root = Dir.pwd
      @storage_config = storage_config
      @ui = ui || UI.null

      @default_attributes = {}
      @override_attributes = {}

      @solution_dependencies = Policyfile::SolutionDependencies.new

      @included_policy_locks = []

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
        lock["revision_id"] = revision_id
        lock["name"] = name
        lock["run_list"] = run_list
        lock["named_run_lists"] = named_run_lists unless named_run_lists.empty?
        lock["included_policy_locks"] = included_policy_locks
        lock["cookbook_locks"] = cookbook_locks_for_lockfile
        lock["default_attributes"] = default_attributes
        lock["override_attributes"] = override_attributes
        lock["solution_dependencies"] = solution_dependencies.to_lock
      end
    end

    # Returns a fingerprint of the PolicyfileLock by computing the SHA1 hash of
    # #canonical_revision_string
    def revision_id
      Digest::SHA256.new.hexdigest(canonical_revision_string)
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

      canonical_rev_text << "default_attributes:#{canonicalize(default_attributes)}\n"

      canonical_rev_text << "override_attributes:#{canonicalize(override_attributes)}\n"

      canonical_rev_text
    end

    def cookbook_locks_for_lockfile
      cookbook_locks.inject({}) do |locks_map, (name, location_spec)|
        location_spec.validate!
        location_spec.gather_profile_data
        locks_map[name] = location_spec.to_lock
        locks_map
      end.sort.to_h
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

      @default_attributes = compiler.default_attributes
      @override_attributes = compiler.override_attributes

      @solution_dependencies = compiler.solution_dependencies

      @included_policy_locks = compiler.included_policies.map do |policy|
        {
          "name" => policy.name,
          "revision_id" => policy.revision_id,
          "source_options" => policy.source_options_for_lock,
        }
      end

      self
    end

    def build_from_lock_data(lock_data)
      set_name_from_lock_data(lock_data)
      set_run_list_from_lock_data(lock_data)
      set_named_run_lists_from_lock_data(lock_data)
      set_cookbook_locks_from_lock_data(lock_data)
      set_attributes_from_lock_data(lock_data)
      set_solution_dependencies_from_lock_data(lock_data)
      set_included_policy_locks_from_lock_data(lock_data)
      self
    end

    def build_from_archive(lock_data)
      set_name_from_lock_data(lock_data)
      set_run_list_from_lock_data(lock_data)
      set_named_run_lists_from_lock_data(lock_data)
      set_cookbook_locks_as_archives_from_lock_data(lock_data)
      set_attributes_from_lock_data(lock_data)
      set_solution_dependencies_from_lock_data(lock_data)
      set_included_policy_locks_from_lock_data(lock_data)
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

    # Generates a canonical JSON representation of the attributes. Based on
    # http://wiki.laptop.org/go/Canonical_JSON but not quite as strict, yet.
    #
    # In particular:
    # - String encoding stuff isn't normalized
    # - We allow floats that fit within the range/precision requirements of
    #   IEEE 754-2008 binary64 (double precision) numbers.
    # - +/- Infinity and NaN are banned, but float/numeric size aren't checked.
    #   numerics should be in range [-(2**53)+1, (2**53)-1] to comply with
    #   IEEE 754-2008
    #
    # Recursive, so absurd nesting levels could cause a SystemError. Invalid
    # input will cause an InvalidPolicyfileAttribute exception.
    def canonicalize(attributes)
      unless attributes.kind_of?(Hash)
        raise "Top level attributes must be a Hash (you gave: #{attributes})"
      end
      canonicalize_elements(attributes)
    end

    def canonicalize_elements(item)
      case item
      when Hash
        # Hash keys will sort differently based on the encoding, but after a
        # JSON round trip everything will be UTF-8, so we have to normalize the
        # keys to UTF-8 first so that the sort order uses the UTF-8 strings.
        item_with_normalized_keys = item.inject({}) do |normalized_item, (key, value)|
          validate_attr_key(key)
          normalized_item[key.encode("utf-8")] = value
          normalized_item
        end
        elements = item_with_normalized_keys.keys.sort.map do |key|
          k = '"' << key << '":'
          v = canonicalize_elements(item_with_normalized_keys[key])
          k << v
        end
        "{" << elements.join(",") << "}"
      when String
        '"' << item.encode("utf-8") << '"'
      when Array
        elements = item.map { |i| canonicalize_elements(i) }
        "[" << elements.join(",") << "]"
      when Integer
        item.to_s
      when Float
        unless item.finite?
          raise InvalidPolicyfileAttribute, "Floating point numbers cannot be infinite or NaN. You gave #{item.inspect}"
        end
        # Support for floats assumes that any implementation of our JSON
        # canonicalization routine will use IEEE-754 doubles. In decimal terms,
        # doubles give 15-17 digits of precision, so we err on the safe side
        # and only use 15 digits in the string conversion. We use the `g`
        # format, which is a documented-enough "do what I mean" where floats
        # >= 0.1 and < precsion are represented as floating point literals, and
        # other numbers use the exponent notation with a lowercase 'e'. Note
        # that both Ruby and Erlang document what their `g` does but have some
        # differences both subtle and non-subtle:
        #
        # ```ruby
        # format("%.15g", 0.1) #=> "0.1"
        # format("%.15g", 1_000_000_000.0) #=> "1000000000"
        # ```
        #
        # Whereas:
        #
        # ```erlang
        # lists:flatten(io_lib:format("~.15g", [0.1])). %=> "0.100000000000000"
        # lists:flatten(io_lib:format("~.15e", [1000000000.0])). %=> "1.00000000000000e+9"
        # ```
        #
        # Other implementations should normalize to ruby's %.15g behavior.
        Kernel.format("%.15g", item)
      when NilClass
        "null"
      when TrueClass
        "true"
      when FalseClass
        "false"
      else
        raise InvalidPolicyfileAttribute,
          "Invalid type in attributes. Only Hash, Array, String, Integer, Float, true, false, and nil are accepted. You gave #{item.inspect} (#{item.class})"
      end
    end

    def validate_attr_key(key)
      unless key.kind_of?(String)
        raise InvalidPolicyfileAttribute,
          "Attribute keys must be Strings (other types are not allowed in JSON). You gave: #{key.inspect} (#{key.class})"
      end
    end

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

    def set_named_run_lists_from_lock_data(lock_data)
      return unless lock_data.key?("named_run_lists")

      lock_data_named_run_lists = lock_data["named_run_lists"]

      unless lock_data_named_run_lists.kind_of?(Hash)
        msg = "lockfile's named_run_lists must be a Hash (JSON object). (got: #{lock_data_named_run_lists.inspect})"
        raise InvalidLockfile, msg
      end

      lock_data_named_run_lists.each do |name, run_list|
        unless name.kind_of?(String)
          msg = "Keys in lockfile's named_run_lists must be Strings. (got: #{name.inspect})"
          raise InvalidLockfile, msg
        end
        unless run_list.kind_of?(Array)
          msg = "Values in lockfile's named_run_lists must be Arrays. (got: #{run_list.inspect})"
          raise InvalidLockfile, msg
        end
        bad_run_list_items = run_list.select { |e| e !~ RUN_LIST_ITEM_FORMAT }
        unless bad_run_list_items.empty?
          msg = "lockfile's run_list items must be formatted like `recipe[$COOKBOOK_NAME::$RECIPE_NAME]'. Invalid items: `#{bad_run_list_items.join("' `")}'"
          raise InvalidLockfile, msg
        end
      end
      @named_run_lists = lock_data_named_run_lists
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

    def set_cookbook_locks_as_archives_from_lock_data(lock_data)
      cookbook_lock_data = lock_data["cookbook_locks"]

      if cookbook_lock_data.nil?
        raise InvalidLockfile, "lockfile does not have a cookbook_locks attribute"
      end

      unless cookbook_lock_data.kind_of?(Hash)
        raise InvalidLockfile, "lockfile's cookbook_locks attribute must be a Hash (JSON object). (got: #{cookbook_lock_data.inspect})"
      end

      lock_data["cookbook_locks"].each do |name, lock_info|
        build_cookbook_lock_as_archive_from_lock_data(name, lock_info)
      end
    end

    def set_attributes_from_lock_data(lock_data)
      default_attr_data = lock_data["default_attributes"]

      if default_attr_data.nil?
        raise InvalidLockfile, "lockfile does not have a `default_attributes` attribute"
      end

      unless default_attr_data.kind_of?(Hash)
        raise InvalidLockfile, "lockfile's `default_attributes` attribute must be a Hash (JSON object). (got: #{default_attr_data.inspect})"
      end

      override_attr_data = lock_data["override_attributes"]

      if override_attr_data.nil?
        raise InvalidLockfile, "lockfile does not have a `override_attributes` attribute"
      end

      unless override_attr_data.kind_of?(Hash)
        raise InvalidLockfile, "lockfile's `override_attributes` attribute must be a Hash (JSON object). (got: #{override_attr_data.inspect})"
      end

      @default_attributes   = default_attr_data
      @override_attributes  = override_attr_data
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

    def set_included_policy_locks_from_lock_data(lock_data)
      locks = lock_data["included_policy_locks"]
      if locks.nil?
        @included_policy_locks = []
      else
        locks.each do |lock_info|
          if !(%w{revision_id name source_options}.all? { |key| !lock_info[key].nil? })
            raise InvalidLockfile, "lockfile included policy missing one of the required keys"
          end
        end
        @included_policy_locks = locks
      end
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

    def build_cookbook_lock_as_archive_from_lock_data(name, lock_info)
      unless lock_info.kind_of?(Hash)
        raise InvalidLockfile, "lockfile cookbook_locks entries must be a Hash (JSON object). (got: #{lock_info.inspect})"
      end

      if lock_info["cache_key"].nil?
        local_cookbook = Policyfile::LocalCookbook.new(name, storage_config)
        local_cookbook.build_from_lock_data(lock_info)
        archived = Policyfile::ArchivedCookbook.new(local_cookbook, storage_config)
        @cookbook_locks[name] = archived
      else
        cached_cookbook = Policyfile::CachedCookbook.new(name, storage_config)
        cached_cookbook.build_from_lock_data(lock_info)
        archived = Policyfile::ArchivedCookbook.new(cached_cookbook, storage_config)
        @cookbook_locks[name] = archived
      end
    end

  end
end
