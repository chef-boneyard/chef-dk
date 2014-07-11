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
require 'chef-dk/cookbook_omnifetch'
require 'chef-dk/policyfile/storage_config'

module ChefDK
  module Policyfile

    class CookbookSpec

      #--
      # Provides #relative_paths_root, which is required by CookbookOmnifetch
      # API contract
      include StorageConfigDelegation

      SOURCE_TYPES = [:git, :github, :path, :artifactserver]

      #--
      # Required by CookbookOmnifetch API contract
      attr_reader :version_constraint

      #--
      # Required by CookbookOmnifetch API contract
      attr_reader :name

      #--
      # Required by CookbookOmnifetch API contract
      attr_reader :source_options
      attr_reader :source_type
      attr_reader :storage_config

      def initialize(name, version_constraint, source_options, storage_config)
        @name = name
        @version_constraint = Semverse::Constraint.new(version_constraint)
        @source_options = source_options
        @source_type = SOURCE_TYPES.find { |type| source_options.key?(type) }
        @storage_config = storage_config
      end

      def ==(other)
        other.kind_of?(self.class) and
          other.name == name and
          other.version_constraint == version_constraint and
          other.source_options == source_options
      end

      def mirrors_canonical_upstream?
        [:git, :github, :artifactserver].include?(source_type)
      end

      def ensure_cached
        unless installer.installed?
          installer.install
        end
      end

      def installer
        @installer ||= CookbookOmnifetch.init(self, source_options)
      end

      def cache_key
        installer.cache_key
      end

      def relative_path
        installer.relative_path.to_s
      end

      def uri
        installer.uri
      end

      def version_fixed?
        [:git, :github, :path].include?(@source_type)
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

      def source_options_for_lock
        installer.lock_data
      end

    end
  end
end
