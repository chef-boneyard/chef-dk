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

require "chef-dk/exceptions"
require "chef/cookbook_loader"
require "chef/cookbook/file_system_file_vendor"
require "chef-dk/ui"

module ChefDK
  module Policyfile
    class ChefRepoCookbookSource

      # path to a chef-repo or the cookbook path under it
      attr_reader :path
      # UI object for output
      attr_accessor :ui

      attr_reader :preferred_cookbooks

      # Constructor
      #
      # @param path [String] path to a chef-repo or the cookbook path under it
      def initialize(path)
        self.path = path
        @ui = UI.new
        @preferred_cookbooks = []
        yield self if block_given?
      end

      def default_source_args
        [:chef_repo, path]
      end

      def preferred_for(*cookbook_names)
        preferred_cookbooks.concat(cookbook_names)
      end

      def preferred_source_for?(cookbook_name)
        preferred_cookbooks.include?(cookbook_name)
      end

      def ==(other)
        other.kind_of?(self.class) && other.path == path && other.preferred_cookbooks == preferred_cookbooks
      end

      # Calls the slurp_metadata! helper once to calculate the @universe_graph
      # and @cookbook_version_paths metadata.  Returns the @universe_graph.
      #
      # @return [Hash] universe_graph
      def universe_graph
        slurp_metadata! if @universe_graph.nil?
        @universe_graph
      end

      # Returns the metadata (path and version) for an individual cookbook
      #
      # @return [Hash] metadata for a single cookbook version
      def source_options_for(cookbook_name, cookbook_version)
        { path: cookbook_version_paths[cookbook_name][cookbook_version], version: cookbook_version }
      end

      def null?
        false
      end

      def desc
        "chef_repo(#{path})"
      end

      private

      # Setter for setting the path.  It may either be a full chef-repo with
      # a cookbooks directory in it, or only a path to the cookbooks directory,
      # and it autodetects which it is passed.
      #
      # @param path [String] path to a chef-repo or the cookbook path under it
      def path=(path)
        cookbooks_path = "#{path}/cookbooks"
        if Dir.exist?(cookbooks_path)
          @path = cookbooks_path
        else
          @path = path
        end
      end

      # Calls the slurp_metadata! helper once to calculate the @universe_graph
      # and @cookbook_version_paths metadata.  Returns the @cookbook_version_paths.
      #
      # @return [Hash] cookbook_version_paths
      def cookbook_version_paths
        slurp_metadata! if @cookbook_version_paths.nil?
        @cookbook_version_paths
      end

      # Helper to compute the @universe_graph and @cookbook_version_paths once
      # from the Chef::CookbookLoader on-disk cookbook repo.
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

      # @return [Chef::CookbookLoader] cookbook loader using on disk FileVendor
      def cookbook_repo
        @cookbook_repo ||= begin
          Chef::Cookbook::FileVendor.fetch_from_disk(path)
          Chef::CookbookLoader.new(path)
        end
      end

    end
  end
end
