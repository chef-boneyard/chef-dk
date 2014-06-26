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

require 'forwardable'

require 'solve'
require 'chef/run_list/run_list_item'

require 'chef-dk/policyfile/dsl'
require 'chef-dk/cookbook_cache_manager'
require 'chef-dk/policyfile_lock'

module ChefDK

  class PolicyfileCompiler

    extend Forwardable

    DEFAULT_DEMAND_CONSTRAINT = '>= 0.0.0'.freeze

    # Cookbooks from these sources lock that cookbook to exactly one version
    SOURCE_TYPES_WITH_FIXED_VERSIONS = [:git, :path].freeze

    def self.evaluate(policyfile_string, policyfile_filename)
      compiler = new
      compiler.evaluate_policyfile(policyfile_string, policyfile_filename)
      compiler
    end

    def_delegator :@dsl, :run_list
    def_delegator :@dsl, :errors
    def_delegator :@dsl, :default_source
    def_delegator :@dsl, :policyfile_cookbook_specs

    attr_reader :dsl

    def initialize
      @dsl = Policyfile::DSL.new
      @artifact_server_cookbook_specs = {}
    end

    def error!
      unless errors.empty?
        raise PolicyfileError, errors.join("\n")
      end
    end

    def cookbook_spec_for(cookbook_name)
      policyfile_cookbook_specs[cookbook_name]
    end

    def expanded_run_list
      run_list
    end

    # TODO: testme
    def lock
      @policyfile_lock ||= PolicyfileLock.build(cache_path: cache_manager.cache_path) do |policyfile_lock|

        policyfile_lock.run_list = expanded_run_list

        all_cookbook_specs.each do |cookbook_name, spec|
          if spec.mirrors_canonical_upstream?
            policyfile_lock.cached_cookbook(cookbook_name) do |cached_cb|
              cached_cb.cache_key = spec.cache_key
              cached_cb.origin = spec.uri
            end
          else
            policyfile_lock.local_cookbook(cookbook_name) do |local_cb|
              local_cb.source = spec.relative_path
            end
          end
        end
      end
    end

    def install
      cache_manager.ensure_cache_dir_exists

      graph_solution.each do |cookbook_name, version|
        spec = cookbook_spec_for(cookbook_name)
        if spec.nil? or !spec.version_fixed?
          spec = create_spec_for_cookbook(cookbook_name, version)
          spec.ensure_cached
        end
      end
    end

    def create_spec_for_cookbook(cookbook_name, version)
      source_options = cache_manager.source_options_for(cookbook_name, version)
      spec = Policyfile::CookbookSpec.new(cookbook_name, "= #{version}", source_options, dsl)
      @artifact_server_cookbook_specs[cookbook_name] = spec
    end

    def all_cookbook_specs
      # in the installation proces, we create "artifact_server_cookbook_specs"
      # for any cookbook that isn't sourced from a single-version source (e.g.,
      # path and git only support one version at a time), but we might have
      # specs for them to track additional version constraint demands. Merging
      # in this order ensures the artifact_server_cookbook_specs "win".
      policyfile_cookbook_specs.merge(@artifact_server_cookbook_specs)
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

    def graph_demands
      cookbooks_for_demands.map do |cookbook_name|
        spec = cookbook_spec_for(cookbook_name)
        if spec.nil?
          [ cookbook_name, DEFAULT_DEMAND_CONSTRAINT ]
        elsif spec.version_fixed?
          [ cookbook_name, "= #{spec.version}" ]
        else
          [ cookbook_name, spec.version_constraint.to_s ]
        end
      end
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
      policyfile_cookbook_specs.inject({}) do |local_artifacts, (cookbook_name, cookbook_spec)|
        if cookbook_spec.version_fixed?
          local_artifacts[cookbook_name] = { cookbook_spec.version => cookbook_spec.dependencies }
        end
        local_artifacts
      end
    end

    def remote_artifacts_graph
      cache_manager.universe_graph
    end

    def version_constraint_for(cookbook_name)
      if (cookbook_spec = cookbook_spec_for(cookbook_name)) and cookbook_spec.version_fixed?
        version = cookbook_spec.version
        "= #{version}"
      else
        DEFAULT_DEMAND_CONSTRAINT
      end
    end

    def cookbook_version_fixed?(cookbook_name)
      if cookbook_spec = cookbook_spec_for(cookbook_name)
        cookbook_spec.version_fixed?
      else
        false
      end
    end

    def cache_manager
      @cache_manager ||= CookbookCacheManager.new(self)
    end

    def cookbooks_in_run_list
      run_list.map {|item_spec| Chef::RunList::RunListItem.new(item_spec).name }
    end

    def build
      yield @dsl
      self
    end

    def evaluate_policyfile(policyfile_string, policyfile_filename)
      @dsl.eval_policyfile(policyfile_string, policyfile_filename)
      self
    end

    private

    def cookbooks_for_demands
      (cookbooks_in_run_list + policyfile_cookbook_specs.keys).uniq
    end

    def cache_fixed_version_cookbooks
      cache_manager.ensure_cache_dir_exists

      policyfile_cookbook_specs.each do |_cookbook_name, cookbook_spec|
        cookbook_spec.ensure_cached if cookbook_spec.version_fixed?
      end
    end


  end
end
