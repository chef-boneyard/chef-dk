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

require "semverse"
require "set"
require "chef-dk/exceptions"

module ChefDK
  module Policyfile

    class SolutionDependencies

      Cookbook = Struct.new(:name, :version)

      class Cookbook

        VALID_STRING_FORMAT = /\A[^\s]+ \([^\s]+\)\Z/.freeze

        def self.valid_str?(str)
          !!(str =~ VALID_STRING_FORMAT)
        end

        def self.parse(str)
          name, version_w_parens = str.split(" ")
          version = version_w_parens[/\(([^)]+)\)/, 1]
          new(name, version)
        end

        def to_s
          "#{name} (#{version})"
        end

        def eql?(other)
          other.kind_of?(self.class) &&
            other.name == name &&
            other.version == version
        end

        def hash
          [name, version].hash
        end

      end

      def self.from_lock(lock_data)
        new.tap { |e| e.consume_lock_data(lock_data) }
      end

      attr_reader :policyfile_dependencies

      attr_reader :cookbook_dependencies

      def initialize
        @policyfile_dependencies = []
        @cookbook_dependencies = {}
      end

      def add_policyfile_dep(cookbook, constraint)
        @policyfile_dependencies << [ cookbook, Semverse::Constraint.new(constraint) ]
      end

      def add_cookbook_dep(cookbook_name, version, dependency_list)
        cookbook = Cookbook.new(cookbook_name, version)
        add_cookbook_obj_dep(cookbook, dependency_list)
      end

      def update_cookbook_dep(cookbook_name, new_version, new_dependency_list)
        @cookbook_dependencies.delete_if { |cb, _deps| cb.name == cookbook_name }
        add_cookbook_dep(cookbook_name, new_version, new_dependency_list)
      end

      def consume_lock_data(lock_data)
        unless lock_data.key?("Policyfile") && lock_data.key?("dependencies")
          msg = %Q|lockfile solution_dependencies must be a Hash of the form `{"Policyfile": [], "dependencies": {} }' (got: #{lock_data.inspect})|
          raise InvalidLockfile, msg
        end

        set_policyfile_deps_from_lock_data(lock_data)
        set_cookbook_deps_from_lock_data(lock_data)
      end

      def test_conflict!(cookbook_name, version)
        unless have_cookbook_dep?(cookbook_name, version)
          raise CookbookNotInWorkingSet, "Cookbook #{cookbook_name} (#{version}) not in the working set, cannot test for conflicts"
        end

        assert_cookbook_version_valid!(cookbook_name, version)
        assert_cookbook_deps_valid!(cookbook_name, version)
      end

      def to_lock
        { "Policyfile" => policyfile_dependencies_for_lock, "dependencies" => cookbook_deps_for_lock }
      end

      def policyfile_dependencies_for_lock
        policyfile_dependencies.map do |name, constraint|
          [ name, constraint.to_s ]
        end.sort
      end

      def cookbook_deps_for_lock
        cookbook_dependencies.inject({}) do |map, (cookbook, deps)|
          map[cookbook.to_s] = deps.map do |name, constraint|
            [ name, constraint.to_s ]
          end
          map
        end.sort.to_h
      end

      def transitive_deps(names)
        deps = Set.new
        to_explore = names.dup
        until to_explore.empty?
          ck_name = to_explore.shift
          next unless deps.add?(ck_name) # explore each ck only once
          my_deps = find_cookbook_dep_by_name(ck_name)
          dep_names = my_deps[1].map(&:first)
          to_explore += dep_names
        end
        deps.to_a.sort
      end

      private

      def add_cookbook_obj_dep(cookbook, dependency_map)
        @cookbook_dependencies[cookbook] = dependency_map.map do |dep_name, constraint|
          [ dep_name, Semverse::Constraint.new(constraint) ]
        end
      end

      def assert_cookbook_version_valid!(cookbook_name, version)
        policyfile_conflicts = policyfile_conflicts_with(cookbook_name, version)
        cookbook_conflicts = cookbook_conflicts_with(cookbook_name, version)
        all_conflicts = policyfile_conflicts + cookbook_conflicts

        return false if all_conflicts.empty?

        details = all_conflicts.map { |source, name, constraint| "#{source} depends on #{name} #{constraint}" }
        message = "Cookbook #{cookbook_name} (#{version}) conflicts with other dependencies:\n"
        full_message = message + details.join("\n")
        raise DependencyConflict, full_message
      end

      def assert_cookbook_deps_valid!(cookbook_name, version)
        dependency_conflicts = cookbook_deps_conflicts_for(cookbook_name, version)
        return false if dependency_conflicts.empty?
        message = "Cookbook #{cookbook_name} (#{version}) has dependency constraints that cannot be met by the existing cookbook set:\n"
        full_message = message + dependency_conflicts.join("\n")
        raise DependencyConflict, full_message
      end

      def policyfile_conflicts_with(cookbook_name, version)
        policyfile_conflicts = []

        @policyfile_dependencies.each do |dep_name, constraint|
          if dep_name == cookbook_name && !constraint.satisfies?(version)
            policyfile_conflicts << ["Policyfile", dep_name, constraint]
          end
        end

        policyfile_conflicts
      end

      def cookbook_conflicts_with(cookbook_name, version)
        cookbook_conflicts = []

        @cookbook_dependencies.each do |top_level_dep_name, dependencies|
          dependencies.each do |dep_name, constraint|
            if dep_name == cookbook_name && !constraint.satisfies?(version)
              cookbook_conflicts << [top_level_dep_name, dep_name, constraint]
            end
          end
        end

        cookbook_conflicts
      end

      def cookbook_deps_conflicts_for(cookbook_name, version)
        conflicts = []
        transitive_deps = find_cookbook_dep_by_name_and_version(cookbook_name, version)
        transitive_deps.each do |name, constraint|
          existing_cookbook = find_cookbook_dep_by_name(name)
          if existing_cookbook.nil?
            conflicts << "Cookbook #{name} isn't included in the existing cookbook set."
          elsif !constraint.satisfies?(existing_cookbook[0].version)
            conflicts << "Dependency on #{name} #{constraint} conflicts with existing version #{existing_cookbook[0]}"
          end
        end
        conflicts
      end

      def have_cookbook_dep?(name, version)
        @cookbook_dependencies.key?(Cookbook.new(name, version))
      end

      def find_cookbook_dep_by_name(name)
        @cookbook_dependencies.find { |k, v| k.name == name }
      end

      def find_cookbook_dep_by_name_and_version(name, version)
        @cookbook_dependencies[Cookbook.new(name, version)]
      end

      def set_policyfile_deps_from_lock_data(lock_data)
        policyfile_deps_data = lock_data["Policyfile"]

        unless policyfile_deps_data.kind_of?(Array)
          msg = "lockfile solution_dependencies Policyfile dependencies must be an array of cookbooks and constraints (got: #{policyfile_deps_data.inspect})"
          raise InvalidLockfile, msg
        end

        policyfile_deps_data.each do |entry|
          add_policyfile_dep_from_lock_data(entry)
        end
      end

      def add_policyfile_dep_from_lock_data(entry)
        unless entry.kind_of?(Array) && entry.size == 2
          msg = %Q{lockfile solution_dependencies Policyfile dependencies entry must be like [ "$COOKBOOK_NAME", "$CONSTRAINT" ] (got: #{entry.inspect})}
          raise InvalidLockfile, msg
        end

        cookbook_name, constraint = entry

        unless cookbook_name.kind_of?(String) && !cookbook_name.empty?
          msg = "lockfile solution_dependencies Policyfile dependencies entry. Cookbook name portion must be a string (got: #{entry.inspect})"
          raise InvalidLockfile, msg
        end

        unless constraint.kind_of?(String) && !constraint.empty?
          msg = "malformed lockfile solution_dependencies Policyfile dependencies entry. Version constraint portion must be a string (got: #{entry.inspect})"
          raise InvalidLockfile, msg
        end
        add_policyfile_dep(cookbook_name, constraint)
      rescue Semverse::InvalidConstraintFormat
        msg = "malformed lockfile solution_dependencies Policyfile dependencies entry. Version constraint portion must be a valid version constraint (got: #{entry.inspect})"
        raise InvalidLockfile, msg
      end

      def set_cookbook_deps_from_lock_data(lock_data)
        cookbook_dependencies_data = lock_data["dependencies"]

        unless cookbook_dependencies_data.kind_of?(Hash)
          msg = "lockfile solution_dependencies dependencies entry must be a Hash (JSON object) of dependencies (got: #{cookbook_dependencies_data.inspect})"
          raise InvalidLockfile, msg
        end

        cookbook_dependencies_data.each do |name_and_version, deps_list|
          add_cookbook_dep_from_lock_data(name_and_version, deps_list)
        end
      end

      def add_cookbook_dep_from_lock_data(name_and_version, deps_list)
        unless name_and_version.kind_of?(String)
          show = "#{name_and_version.inspect} => #{deps_list.inspect}"
          msg = %Q{lockfile cookbook_dependencies entries must be of the form "$COOKBOOK_NAME ($VERSION)" => [ $dependency, ...] (got: #{show}) }
          raise InvalidLockfile, msg
        end

        unless Cookbook.valid_str?(name_and_version)
          msg = %Q{lockfile cookbook_dependencies entry keys must be of the form "$COOKBOOK_NAME ($VERSION)" (got: #{name_and_version.inspect}) }
          raise InvalidLockfile, msg
        end

        unless deps_list.kind_of?(Array)
          msg = %Q{lockfile cookbook_dependencies entry values must be an Array like [ [ "$COOKBOOK_NAME", "$CONSTRAINT" ], ... ] (got: #{deps_list.inspect}) }
          raise InvalidLockfile, msg
        end

        deps_list.each do |entry|

          unless entry.kind_of?(Array) && entry.size == 2
            msg = %Q{lockfile solution_dependencies dependencies entry must be like [ "$COOKBOOK_NAME", "$CONSTRAINT" ] (got: #{entry.inspect})}
            raise InvalidLockfile, msg
          end

          dep_name, constraint = entry

          unless dep_name.kind_of?(String) && !dep_name.empty?
            msg = "malformed lockfile solution_dependencies dependencies entry. Cookbook name portion must be a string (got: #{entry.inspect})"
            raise InvalidLockfile, msg
          end

          unless constraint.kind_of?(String) && !constraint.empty?
            msg = "malformed lockfile solution_dependencies dependencies entry. Version constraint portion must be a string (got: #{entry.inspect})"
            raise InvalidLockfile, msg
          end
        end

        cookbook = Cookbook.parse(name_and_version)
        add_cookbook_obj_dep(cookbook, deps_list)
      end

    end

  end
end
