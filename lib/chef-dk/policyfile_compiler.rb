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

require 'chef-dk/policyfile/dsl'
require 'chef/run_list/run_list_item'
require 'forwardable'

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
    def_delegator :@dsl, :cookbook_source_overrides

    attr_reader :dsl

    def initialize
      @dsl = Policyfile::DSL.new
    end

    ##
    # DSL Methods
    ##

    ##
    # Compilation Methods
    ##

    def graph_demands
      cookbooks_in_run_list.map do |cookbook_name, version_constraint|
        [ cookbook_name, version_constraint_for(cookbook_name) ]
      end
    end

    def artifacts_graph
      remote_artifacts_graph.merge(local_artifacts_graph)
    end

    def local_artifacts_graph
      cookbooks_in_run_list.inject({}) do |local_artifacts, cookbook_name|
        if cookbook_version_fixed?(cookbook_name)
          local_artifacts[cookbook_name] = cache_manager.cookbook_dependencies(cookbook_name)
        end
        local_artifacts
      end
    end

    def remote_artifacts_graph
      cache_manager.universe_graph
    end

    def version_constraint_for(cookbook_name)
      if cookbook_version_fixed?(cookbook_name)
        version = cache_manager.cookbook_version(cookbook_name)
        "= #{version}"
      else
        DEFAULT_DEMAND_CONSTRAINT
      end
    end

    def cookbook_version_fixed?(cookbook_name)
      if source_options = cookbook_source_overrides[cookbook_name]
        SOURCE_TYPES_WITH_FIXED_VERSIONS.any? { |type| source_options.key?(type) }
      else
        false
      end
    end

    def cache_manager
      raise "TODO"
    end

    def run_list_graph_demands
      cookbooks_in_run_list.map {|cookbook_name| [cookbook_name, DEFAULT_DEMAND_CONSTRAINT] }
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

  end
end
