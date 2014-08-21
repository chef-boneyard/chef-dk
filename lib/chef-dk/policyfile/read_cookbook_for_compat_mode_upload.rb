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

require 'chef/cookbook/cookbook_version_loader'

require 'chef/cookbook/chefignore'

module ChefDK
  module Policyfile
    class ReadCookbookForCompatModeUpload

      # Convenience method to load a cookbook, set up name and version overrides
      # as necessary, and return a Chef::CookbookVersion object.
      def self.load(name, version_override, directory_path)
        new(name, version_override, directory_path).cookbook_version
      end

      attr_reader :cookbook_name
      attr_reader :directory_path
      attr_reader :version_override

      def initialize(cookbook_name, version_override, directory_path)
        @cookbook_name = cookbook_name
        @version_override = version_override
        @directory_path = directory_path

        @cookbook_version = nil
        @loader = nil
      end

      def cookbook_version
        @cookbook_version ||=
          begin
            cookbook_version = loader.cookbook_version
            cookbook_version.version = version_override
            cookbook_version.freeze_version
            cookbook_version
          end
      end

      def loader
        @loader ||=
          begin
            cbvl = Chef::Cookbook::CookbookVersionLoader.new(directory_path, chefignore)
            cbvl.load!
            cbvl
          end
      end

      def chefignore
        @chefignore ||= Chef::Cookbook::Chefignore.new(File.join(directory_path, "chefignore"))
      end

    end
  end
end
