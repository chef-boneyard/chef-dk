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

require 'semverse'

require 'chef-dk/exceptions'

module ChefDK
  module Policyfile

    class SolutionDependencies

      Cookbook = Struct.new(:name, :version)

      class Cookbook

        def self.parse(str)
          name, version_w_parens = str.split(' ')
          version = version_w_parens[/\(([^)]+)\)/, 1]
          new(name, version)
        end

        def to_s
          "#{name} (#{version})"
        end

        def eql?(other)
          other.kind_of?(self.class) and
            other.name == name and
            other.version == version
        end

        def hash
          [name, version].hash
        end

      end

      attr_reader :policyfile_dependencies

      attr_reader :cookbook_dependencies

      def initialize
        @policyfile_dependencies = []
        @cookbook_dependencies = {}
      end

      def cookbook_deps_for_lock
        cookbook_dependencies.inject({}) do |map, (cookbook, deps)|
          map[cookbook.to_s] = deps
          map
        end
      end

      def consume_lock_data(lock_data)
        policyfile_dependencies_data = lock_data["Policyfile"] || []
        policyfile_dependencies_data.each do |cookbook_name, constraint|
          add_policyfile_dep(cookbook_name, constraint)
        end
        cookbook_dependencies_data = lock_data["dependencies"] || {}
        cookbook_dependencies_data.each do |name_and_version, deps_list|
          cookbook = Cookbook.parse(name_and_version)
          add_cookbook_obj_dep(cookbook, deps_list)
        end
      end

      def test_conflict!(cookbook_name, version)
        policyfile_conflicts = policyfile_conflicts_with(cookbook_name, version)
        cookbook_conflicts = cookbook_conflicts_with(cookbook_name, version)
        all_conflicts = policyfile_conflicts + cookbook_conflicts

        return false if all_conflicts.empty?

        details = all_conflicts.map { |source, name, constraint| "#{source} depends on #{name} #{constraint}" }
        message = "Cookbook #{cookbook_name} (#{version}) conflicts with other dependencies:\n"
        full_message = message + details.join("\n")
        raise DependencyConflict, full_message
      end

      def add_policyfile_dep(cookbook, constraint)
        @policyfile_dependencies << [ cookbook, Semverse::Constraint.new(constraint) ]
      end

      def add_cookbook_dep(cookbook_name, version, dependency_map)
        cookbook = Cookbook.new(cookbook_name, version)
        add_cookbook_obj_dep(cookbook, dependency_map)
      end

      private

      def add_cookbook_obj_dep(cookbook, dependency_map)
        @cookbook_dependencies[cookbook] = dependency_map.map do |dep_name, constraint|
          [ dep_name, Semverse::Constraint.new(constraint) ]
        end
      end

      def policyfile_conflicts_with(cookbook_name, version)
        policyfile_conflicts = []

        @policyfile_dependencies.each do |dep_name, constraint|
          if dep_name == cookbook_name and !constraint.satisfies?(version)
            policyfile_conflicts << ['Policyfile', dep_name, constraint]
          end
        end

        policyfile_conflicts
      end

      def cookbook_conflicts_with(cookbook_name, version)
        cookbook_conflicts = []

        @cookbook_dependencies.each do |top_level_dep_name, dependencies|
          dependencies.each do |dep_name, constraint|
            if dep_name == cookbook_name and !constraint.satisfies?(version)
              cookbook_conflicts << [top_level_dep_name, dep_name, constraint]
            end
          end
        end

        cookbook_conflicts
      end

    end

  end
end
