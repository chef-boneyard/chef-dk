#
# Copyright:: Copyright (c) 2017 Chef Software Inc.
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

require "json"
require "chef-dk/cookbook_omnifetch"
require "chef-dk/policyfile/source_uri"
require "chef-dk/exceptions"
require "chef/http/simple"

module ChefDK
  module Policyfile
    class ArtifactoryCookbookSource

      attr_reader :uri
      attr_reader :preferred_cookbooks
      attr_reader :chef_config

      def initialize(uri, chef_config: nil)
        @uri = uri
        @http_connections = {}
        @chef_config = chef_config
        @preferred_cookbooks = []
        yield self if block_given?
      end

      def default_source_args
        [:artifactory, uri]
      end

      def ==(other)
        other.kind_of?(self.class) && other.uri == uri && other.preferred_cookbooks == preferred_cookbooks
      end

      def preferred_for(*cookbook_names)
        preferred_cookbooks.concat(cookbook_names)
      end

      def preferred_source_for?(cookbook_name)
        preferred_cookbooks.include?(cookbook_name)
      end

      def universe_graph
        @universe_graph ||= begin
          full_community_graph.inject({}) do |normalized_graph, (cookbook_name, metadata_by_version)|
            normalized_graph[cookbook_name] = metadata_by_version.inject({}) do |deps_by_version, (version, metadata)|
              deps_by_version[version] = metadata["dependencies"]
              deps_by_version
            end
            normalized_graph
          end
        end
      end

      def source_options_for(cookbook_name, cookbook_version)
        base_uri = full_community_graph[cookbook_name][cookbook_version]["download_url"]
        {
          artifactory: base_uri,
          version: cookbook_version,
          http_client: http_connection_for(base_uri.to_s),
        }
      end

      def null?
        false
      end

      def desc
        "artifactory(#{uri})"
      end

      private

      def http_connection_for(base_url)
        headers = { "X-Jfrog-Art-API" => chef_config.artifactory_api_key || ENV["ARTIFACTORY_API_KEY"] }
        @http_connections[base_url] ||= Chef::HTTP::Simple.new(base_url, headers: headers)
      end

      def full_community_graph
        @full_community_graph ||=
          begin
            graph_json = http_connection_for(uri).get("/universe")
            JSON.parse(graph_json)
          end
      end

    end
  end
end
