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

require 'chef-dk/exceptions'
require 'chef/cookbook_loader'
require 'chef/cookbook/file_system_file_vendor'
require 'chef-dk/ui'

module ChefDK
  module Policyfile
    class ChefRepoCookbookSource

      attr_reader :path
      attr_accessor :ui

      def initialize(path)
        @path = path
        @ui = UI.new
      end

      def ==(other)
        other.kind_of?(self.class) && other.path == path
      end

      def universe_graph
        slurp_metadata! if @universe_graph.nil?
        @universe_graph
      end

      def source_options_for(cookbook_name, cookbook_version)
        { path: cookbook_version_paths[cookbook_name][cookbook_version], version: cookbook_version }
      end

      private

      def cookbook_version_paths
        slurp_metadata! if @cookbook_version_paths.nil?
        @cookbook_version_paths
      end

      def slurp_metadata!
        @universe_graph = {}
        @cookbook_version_paths = {}
        cookbook_repo.load_cookbooks
        cookbook_repo.each do |cookbook_name, cookbook_version|
          metadata = cookbook_version.metadata
          if metadata.name.nil?
            ui.err("WARN: #{cookbook_name} cookbook missing metadata or no name field, skipping")
            next
          end
          @universe_graph[metadata.name] ||= {}
          @universe_graph[metadata.name][metadata.version] = metadata.dependencies.to_a
          @cookbook_version_paths[metadata.name] ||= {}
          @cookbook_version_paths[metadata.name][metadata.version] = cookbook_version.root_dir
        end
      end

      def cookbook_repo
        @cookbook_repo ||= begin
          Chef::Cookbook::FileVendor.fetch_from_disk(path)
          Chef::CookbookLoader.new(path)
        end
      end

    end
  end
end
