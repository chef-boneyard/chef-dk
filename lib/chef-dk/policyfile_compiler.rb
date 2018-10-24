#
# Copyright:: Copyright (c) 2014-2018, Chef Software Inc.
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

require "set"
require "forwardable"

require "solve"
require "chef/run_list"
require "chef/mixin/deep_merge"

require "chef-dk/policyfile/dsl"
require "chef-dk/policyfile/attribute_merge_checker"
require "chef-dk/policyfile/included_policies_cookbook_source"
require "chef-dk/policyfile_lock"
require "chef-dk/ui"
require "chef-dk/policyfile/reports/install"
require "chef-dk/exceptions"

module ChefDK

  class PolicyfileCompiler

    extend Forwardable

    DEFAULT_DEMAND_CONSTRAINT = ">= 0.0.0".freeze

    # Cookbooks from these sources lock that cookbook to exactly one version
    SOURCE_TYPES_WITH_FIXED_VERSIONS = [:git, :path].freeze

    def self.evaluate(policyfile_string, policyfile_filename, ui: nil, chef_config: nil)
      compiler = new(ui: ui, chef_config: chef_config)
      compiler.evaluate_policyfile(policyfile_string, policyfile_filename)
      compiler
    end

    def_delegator :@dsl, :name
    def_delegator :@dsl, :run_list
    def_delegator :@dsl, :named_run_list
    def_delegator :@dsl, :named_run_lists
    def_delegator :@dsl, :errors
    def_delegator :@dsl, :cookbook_location_specs
    def_delegator :@dsl, :included_policies

    attr_reader :dsl
    attr_reader :storage_config
    attr_reader :install_report

    def initialize(ui: nil, chef_config: nil)
      @storage_config = Policyfile::StorageConfig.new
      @dsl = Policyfile::DSL.new(storage_config, chef_config: chef_config)
      @artifact_server_cookbook_location_specs = {}

      @merged_graph = nil

      @ui = ui || UI.null
      @install_report = Policyfile::Reports::Install.new(ui: @ui, policyfile_compiler: self)
    end

    def default_source(source_type = nil, source_argument = nil, &block)
      if source_type.nil?
        prepend_array = if included_policies.length > 0
                          [included_policies_cookbook_source]
                        else
                          []
                        end
        prepend_array + dsl.default_source
      else
        dsl.default_source(source_type, source_argument, &block)
      end
    end

    def error!
      unless errors.empty?
        raise PolicyfileError, errors.join("\n")
      end
    end

    def cookbook_location_spec_for(cookbook_name)
      cookbook_location_specs[cookbook_name]
    end

    def expanded_run_list
      # doesn't support roles yet...
      concated_runlist = Chef::RunList.new
      included_policies.each do |policy_spec|
        lock = policy_spec.policyfile_lock
        lock.run_list.each do |run_list_item|
          concated_runlist << run_list_item
        end
      end
      run_list.each do |run_list_item|
        concated_runlist << run_list_item
      end
      concated_runlist
    end

    # copy of the expanded_run_list, properly formatted for use in a lockfile
    def normalized_run_list
      expanded_run_list.map { |i| normalize_recipe(i) }
    end

    def expanded_named_run_lists
      included_policies_named_runlists = included_policies.inject({}) do |acc, policy_spec|
        lock = policy_spec.policyfile_lock
        lock.named_run_lists.inject(acc) do |expanded, (name, run_list_items)|
          expanded[name] ||= Chef::RunList.new
          run_list_items.each do |run_list_item|
            expanded[name] << run_list_item
          end
          expanded
        end
        acc
      end

      named_run_lists.inject(included_policies_named_runlists) do |expanded, (name, run_list_items)|
        expanded[name] ||= Chef::RunList.new
        run_list_items.each do |run_list_item|
          expanded[name] << run_list_item
        end
        expanded
      end
    end

    def normalized_named_run_lists
      expanded_named_run_lists.inject({}) do |normalized, (name, run_list)|
        normalized[name] = run_list.map { |i| normalize_recipe(i) }
        normalized
      end
    end

    def default_attributes
      check_for_default_attribute_conflicts!
      included_policies.map { |p| p.policyfile_lock }.inject(
        dsl.node_attributes.combined_default.to_hash) do |acc, lock|
          Chef::Mixin::DeepMerge.merge(acc, lock.default_attributes)
        end
    end

    def override_attributes
      check_for_override_attribute_conflicts!
      included_policies.map { |p| p.policyfile_lock }.inject(
        dsl.node_attributes.combined_override.to_hash) do |acc, lock|
          Chef::Mixin::DeepMerge.merge(acc, lock.override_attributes)
        end
    end

    def lock
      @policyfile_lock ||= PolicyfileLock.build_from_compiler(self, storage_config)
    end

    def install
      ensure_cache_dir_exists

      cookbook_and_recipe_list = combined_run_lists.map(&:name).map do |recipe_spec|
        cookbook, _separator, recipe = recipe_spec.partition("::")
        recipe = "default" if recipe.empty?
        [cookbook, recipe]
      end

      missing_recipes_by_cb_spec = {}

      graph_solution.each do |cookbook_name, version|
        spec = cookbook_location_spec_for(cookbook_name)
        if spec.nil? || !spec.version_fixed?
          spec = create_spec_for_cookbook(cookbook_name, version)
          install_report.installing_cookbook(spec)
          spec.ensure_cached
        end

        required_recipes = cookbook_and_recipe_list.select { |cb_name, _recipe| cb_name == spec.name }
        missing_recipes = required_recipes.select { |_cb_name, recipe| !spec.cookbook_has_recipe?(recipe) }

        unless missing_recipes.empty?
          missing_recipes_by_cb_spec[spec] = missing_recipes
        end
      end

      unless missing_recipes_by_cb_spec.empty?
        message = "The installed cookbooks do not contain all the recipes required by your run list(s):\n"
        missing_recipes_by_cb_spec.each do |spec, missing_items|
          message << "#{spec}\nis missing the following required recipes:\n"
          missing_items.each { |_cb, recipe| message << "* #{recipe}\n" }
        end

        message << "\n"
        message << "You may have specified an incorrect recipe in your run list,\nor this recipe may not be available in that version of the cookbook\n"

        raise CookbookDoesNotContainRequiredRecipe, message
      end
    end

    def create_spec_for_cookbook(cookbook_name, version)
      matching_source = best_source_for(cookbook_name)
      source_options = matching_source.source_options_for(cookbook_name, version)
      spec = Policyfile::CookbookLocationSpecification.new(cookbook_name, "= #{version}", source_options, storage_config)
      @artifact_server_cookbook_location_specs[cookbook_name] = spec
    end

    def all_cookbook_location_specs
      # in the installation process, we create "artifact_server_cookbook_location_specs"
      # for any cookbook that isn't sourced from a single-version source (e.g.,
      # path and git only support one version at a time), but we might have
      # specs for them to track additional version constraint demands. Merging
      # in this order ensures the artifact_server_cookbook_location_specs "win".
      cookbook_location_specs.merge(@artifact_server_cookbook_location_specs)
    end

    ##
    # Compilation Methods
    ##

    def graph_solution
      return @solution if @solution
      cache_fixed_version_cookbooks
      @solution = Solve.it!(graph, graph_demands)
    end

    def graph
      @graph ||= Solve::Graph.new.tap do |g|
        artifacts_graph.each do |name, dependencies_by_version|
          dependencies_by_version.each do |version, dependencies|
            artifact = g.artifact(name, version)
            dependencies.each do |dep_name, constraint|
              artifact.dependency(dep_name, constraint)
            end
          end
        end
      end
    end

    def solution_dependencies
      solution_deps = Policyfile::SolutionDependencies.new

      all_cookbook_location_specs.each do |name, spec|
        solution_deps.add_policyfile_dep(name, spec.version_constraint)
      end

      graph_solution.each do |name, version|
        transitive_deps = artifacts_graph[name][version]
        solution_deps.add_cookbook_dep(name, version, transitive_deps)
      end
      solution_deps
    end

    def graph_demands
      ## TODO: By merging cookbooks from the current policyfile and included policies,
      #        we lose the ability to know where a conflict came from
      (cookbook_demands_from_current + cookbook_demands_from_policies)
    end

    def artifacts_graph
      remote_artifacts_graph.merge(local_artifacts_graph)
    end

    # Gives a dependency graph for cookbooks that are source from an alternate
    # location. These cookbooks could have a different set of dependencies
    # compared to an unmodified copy upstream. For example, the community site
    # may have a cookbook "apache2" at version "1.10.4", which the user has
    # forked on github and modified the dependencies without changing the
    # version number. To accomodate this, the local_artifacts_graph should be
    # merged over the upstream's artifacts graph.
    def local_artifacts_graph
      cookbook_location_specs.inject({}) do |local_artifacts, (cookbook_name, cookbook_location_spec)|
        if cookbook_location_spec.version_fixed?
          local_artifacts[cookbook_name] = { cookbook_location_spec.version => cookbook_location_spec.dependencies }
        end
        local_artifacts
      end
    end

    def remote_artifacts_graph
      @merged_graph ||=
        begin
          conflicting_cb_names = []
          merged = {}
          default_source.each do |source|
            merged.merge!(source.universe_graph) do |conflicting_cb_name, _old, _new|
              if (preference = preferred_source_for_cookbook(conflicting_cb_name))
                preference.universe_graph[conflicting_cb_name]
              elsif cookbook_could_appear_in_solution?(conflicting_cb_name)
                conflicting_cb_names << conflicting_cb_name
                {} # return empty set of versions
              else
                {} # return empty set of versions
              end
            end
          end
          handle_conflicting_cookbooks(conflicting_cb_names)
          merged
        end
    end

    def version_constraint_for(cookbook_name)
      if (cookbook_location_spec = cookbook_location_spec_for(cookbook_name)) && cookbook_location_spec.version_fixed?
        version = cookbook_location_spec.version
        "= #{version}"
      else
        DEFAULT_DEMAND_CONSTRAINT
      end
    end

    def cookbook_version_fixed?(cookbook_name)
      if ( cookbook_location_spec = cookbook_location_spec_for(cookbook_name) )
        cookbook_location_spec.version_fixed?
      else
        false
      end
    end

    def cookbooks_in_run_list
      recipes = combined_run_lists.map { |recipe| recipe.name }
      recipes.map { |r| r[/^([^:]+)/, 1] }
    end

    def combined_run_lists
      expanded_named_run_lists.values.inject(expanded_run_list.to_a) do |accum_run_lists, run_list|
        accum_run_lists | run_list.to_a
      end
    end

    def combined_run_lists_by_cb_name
      combined_run_lists.inject({}) do |by_name_accum, run_list_item|
        by_name_accum
      end
    end

    def build
      yield @dsl
      self
    end

    def evaluate_policyfile(policyfile_string, policyfile_filename)
      storage_config.use_policyfile(policyfile_filename)
      @dsl.eval_policyfile(policyfile_string)
      self
    end

    def fixed_version_cookbooks_specs
      @fixed_version_cookbooks_specs ||= cookbook_location_specs.select do |_cookbook_name, cookbook_location_spec|
        cookbook_location_spec.version_fixed?
      end
    end

    private

    def normalize_recipe(run_list_item)
      name = run_list_item.name
      name = "#{name}::default" unless name.include?("::")
      "recipe[#{name}]"
    end

    def cookbooks_for_demands
      (cookbooks_in_run_list + cookbook_location_specs.keys).uniq
    end

    def cache_fixed_version_cookbooks
      ensure_cache_dir_exists

      fixed_version_cookbooks_specs.each do |name, cookbook_location_spec|
        install_report.installing_fixed_version_cookbook(cookbook_location_spec)
        cookbook_location_spec.ensure_cached
      end
    end

    def ensure_cache_dir_exists
      unless File.exist?(cache_path)
        FileUtils.mkdir_p(cache_path)
      end
    end

    def cache_path
      CookbookOmnifetch.storage_path
    end

    def best_source_for(cookbook_name)
      preferred = default_source.find { |s| s.preferred_source_for?(cookbook_name) }
      if preferred.nil?
        default_source.find do |s|
          s.universe_graph.key?(cookbook_name)
        end
      else
        preferred
      end
    end

    def preferred_source_for_cookbook(conflicting_cb_name)
      default_source.find { |s| s.preferred_source_for?(conflicting_cb_name) }
    end

    def handle_conflicting_cookbooks(conflicting_cookbooks)
      # ignore any cookbooks that have a source set.
      cookbooks_wo_source = conflicting_cookbooks.select do |cookbook_name|
        location_spec = cookbook_location_spec_for(cookbook_name)
        location_spec.nil? || location_spec.source_options.empty?
      end

      if cookbooks_wo_source.empty?
        nil
      else
        raise CookbookSourceConflict.new(cookbooks_wo_source, default_source)
      end
    end

    def cookbook_could_appear_in_solution?(cookbook_name)
      all_possible_dep_names.include?(cookbook_name)
    end

    # Traverses the dependency graph in a simple manner to find the set of
    # cookbooks that could be considered in the dependency solution. Version
    # constraints are not considered so this could include extra cookbooks.
    def all_possible_dep_names
      @all_possible_dep_names ||= cookbooks_for_demands.inject(Set.new) do |deps_set, demand_cookbook|

        deps_set_for_source = default_source.inject(Set.new) do |deps_set_for_cb, source|
          possible_deps = possible_dependencies_of(demand_cookbook, source)
          deps_set_for_cb.merge(possible_deps)
        end

        deps_set.merge(deps_set_for_source)
      end
    end

    def possible_dependencies_of(cookbook_name, source, dependency_set = Set.new)
      return dependency_set if dependency_set.include?(cookbook_name)
      return dependency_set unless source.universe_graph.key?(cookbook_name)

      dependency_set << cookbook_name

      deps_by_version = source.universe_graph[cookbook_name]

      dep_cookbook_names = deps_by_version.values.inject(Set.new) do |names, constraint_list|
        names.merge(constraint_list.map { |c| c.first })
      end

      dep_cookbook_names.each do |dep_cookbook_name|
        possible_dependencies_of(dep_cookbook_name, source, dependency_set)
      end

      dependency_set
    end

    def check_for_default_attribute_conflicts!
      checker = Policyfile::AttributeMergeChecker.new
      checker.with_attributes("user-specified", dsl.node_attributes.combined_default)
      included_policies.map do |policy_spec|
        lock = policy_spec.policyfile_lock
        checker.with_attributes(policy_spec.name, lock.default_attributes)
      end
      checker.check!
    end

    def check_for_override_attribute_conflicts!
      checker = Policyfile::AttributeMergeChecker.new
      checker.with_attributes("user-specified", dsl.node_attributes.combined_override)
      included_policies.map do |policy_spec|
        lock = policy_spec.policyfile_lock
        checker.with_attributes(policy_spec.name, lock.override_attributes)
      end
      checker.check!
    end

    def cookbook_demands_from_policies
      included_policies.flat_map do |policy_spec|
        lock = policy_spec.policyfile_lock
        lock.solution_dependencies.to_lock["Policyfile"]
      end
    end

    def cookbook_demands_from_current
      cookbooks_for_demands.map do |cookbook_name|
        spec = cookbook_location_spec_for(cookbook_name)
        if spec.nil?
          [ cookbook_name, DEFAULT_DEMAND_CONSTRAINT ]
        elsif spec.version_fixed?
          [ cookbook_name, "= #{spec.version}" ]
        else
          [ cookbook_name, spec.version_constraint.to_s ]
        end
      end
    end

    def included_policies_cookbook_source
      @included_policies_cookbook_source ||= begin
        source = Policyfile::IncludedPoliciesCookbookSource.new(included_policies)
        handle_included_policies_preferred_cookbook_conflicts(source)
        source
      end
    end

    def handle_included_policies_preferred_cookbook_conflicts(included_policies_source)
      # All cookbooks in the included policies are preferred.
      conflicting_source_messages = []
      dsl.default_source.reject { |s| s.null? }.each do |source_b|
        conflicting_preferences = included_policies_source.preferred_cookbooks & source_b.preferred_cookbooks
        next if conflicting_preferences.empty?
        next if conflicting_preferences.all? do |cookbook_name|
          version = included_policies_source.universe_graph[cookbook_name].keys.first
          if included_policies_source.source_options_for(cookbook_name, version) == source_b.source_options_for(cookbook_name, version)
            true
          else
            false
          end
        end
        conflicting_source_messages << "#{source_b.desc} sets a preferred for cookbook(s) #{conflicting_preferences.join(', ')}. This conflicts with an included policy."
      end
      unless conflicting_source_messages.empty?
        msg = "You may not override the cookbook sources for any cookbooks required by included policies.\n"
        msg << conflicting_source_messages.join("\n") << "\n"
        raise IncludePolicyCookbookSourceConflict.new(msg)
      end
    end

  end
end
