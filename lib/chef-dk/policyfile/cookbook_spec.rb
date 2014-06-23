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
require 'cookbook-omnifetch'

module ChefDK
  module Policyfile

    # TODO: tests.
    class CookbookSpec

      SOURCE_TYPES = [:git, :github, :path]

      attr_reader :version_constraint
      attr_reader :name
      attr_reader :source_options

      def initialize(name, version_constraint, source_options, policyfile_filename)
        @name = name
        @version_constraint = Semverse::Constraint.new(version_constraint)
        @source_options = source_options
        @policyfile_filename = policyfile_filename
        @source_type = SOURCE_TYPES.find { |type| source_options.key?(type) }
      end

      def ==(other)
        other.kind_of?(self.class) and
          other.name == name and
          other.source_options == source_options
      end

      def ensure_cached
        installer.install unless installer.installed?
      end

      def installer
        @installer ||= CookbookOmnifetch.init(self, source_options)
      end

      # TODO: this won't be true for community site or chef-server sourced cookbooks
      def version_fixed?
        true
      end

      def version
        cached_cookbook.version
      end

      def dependencies
        cached_cookbook.dependencies
      end

      def cached_cookbook
        installer.cached_cookbook
      end

      def relative_paths_root
        File.dirname(@policyfile_filename)
      end

    end
  end
end
