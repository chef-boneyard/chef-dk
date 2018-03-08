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

require "chef-dk/ui"

module ChefDK
  module Policyfile
    class IncludedPoliciesCookbookSource

      class ConflictingCookbookVersions < StandardError
      end

      class ConflictingCookbookDependencies < StandardError
      end

      class ConflictingCookbookSources < StandardError
      end

      # Why do we need this class?
      # If we rely on default sources, we may not have the the universe of cookbooks
      # provided in the included policies
      #
      # This is not meant to be used from the DSL

      # A list of included policies
      attr_reader :included_policy_location_specs
      # UI object for output
      attr_accessor :ui

      # Constructor
      #
      def initialize(included_policy_location_specs)
        @included_policy_location_specs = included_policy_location_specs
        @ui = UI.new
        @preferred_cookbooks = []
        yield self if block_given?
      end

      def default_source_args
        [:included_policies, []]
      end

      def check_for_conflicts!
        source_options
        universe_graph
      end

      # All are preferred here
      def preferred_source_for?(cookbook_name)
        universe_graph.include?(cookbook_name)
      end

      def preferred_cookbooks
        universe_graph.keys
      end

      def ==(other)
        other.kind_of?(self.class) && other.included_policy_location_specs == included_policy_location_specs
      end

      # Calls the slurp_metadata! helper once to calculate the @universe_graph
      # and @cookbook_version_paths metadata.  Returns the @universe_graph.
      #
      # @return [Hash] universe_graph
      def universe_graph
        @universe_graph ||= build_universe
      end

      # Returns the metadata (path and version) for an individual cookbook
      #
      # @return [Hash] metadata for a single cookbook version
      def source_options_for(cookbook_name, cookbook_version)
        source_options[cookbook_name][cookbook_version]
      end

      def null?
        false
      end

      def desc
        "included_policies()"
      end

      private

      def build_universe
        included_policy_location_specs.inject({}) do |acc, policy_spec|
          lock = policy_spec.policyfile_lock
          cookbook_dependencies = lock.solution_dependencies.cookbook_dependencies
          cookbook_dependencies.each do |(cookbook, deps)|
            name = cookbook.name
            version = cookbook.version
            mapped_deps = deps.map do |dep|
              [dep[0], dep[1].to_s]
            end
            if acc[name]
              if acc[name][version]
                if acc[name][version] != mapped_deps
                  raise ConflictingCookbookDependencies.new("Conflicting dependencies provided for cookbook #{name}")
                end
              else
                raise ConflictingCookbookVersions.new("Multiple versions provided for cookbook #{name}")
              end
            else
              acc[name] = {}
              acc[name][version] = mapped_deps
            end
          end
          acc
        end
      end

      def source_options
        @source_options ||= build_source_options
      end

      ## Collect all the source options
      def build_source_options
        included_policy_location_specs.inject({}) do |acc, policy_spec|
          lock = policy_spec.policyfile_lock
          lock.cookbook_locks.each do |(name, cookbook_lock)|
            version = cookbook_lock.version
            if acc[name]
              if acc[name][version]
                if acc[name][version] != cookbook_lock.source_options
                  raise ConflictingCookbookSources.new("Conflicting sources provided for cookbook #{name}")
                end
              else
                raise ConflictingCookbookVersions.new("Multiple sources provided for cookbook #{name}")
              end
            else
              acc[name] = {}
              acc[name][version] = cookbook_lock.source_options
            end
          end
          acc
        end
      end

    end
  end
end
