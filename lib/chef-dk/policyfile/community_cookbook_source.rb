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

require 'json'
require 'chef-dk/cookbook_omnifetch'
require 'chef-dk/exceptions'
# TODO: chef bug. Chef::HTTP::Simple needs to require this itself.
# Fixed in 2ed829e661f9a357fc9a8cdf316c84f077dad7f9 waiting for that to be
# released...
require 'tempfile'
require 'chef/platform/query_helpers' # should be handled by http/simple
require 'chef/http/cookie_manager' # should be handled by http/simple
require 'chef/http/validate_content_length' # should be handled by http/simple
require 'chef/http/simple'

# TODO: fix hardcoding
Chef::Config.ssl_verify_mode = :verify_peer

module ChefDK
  module Policyfile

    class CommunityCookbookSource

      attr_reader :uri

      def initialize(uri = nil)
        @uri = uri || "https://supermarket.getchef.com"
        @http_connections = {}
      end

      def ==(other)
        other.kind_of?(self.class) && other.uri == uri
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
        { artifactserver: base_uri, version: cookbook_version }
      end

      private

      def http_connection_for(base_url)
        @http_connections[base_url] ||= Chef::HTTP::Simple.new(base_url)
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

