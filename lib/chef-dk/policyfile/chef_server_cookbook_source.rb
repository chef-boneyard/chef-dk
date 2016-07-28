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

require 'ffi_yajl'
require 'chef-dk/exceptions'
require 'chef-dk/policyfile/source_uri'
require 'chef-dk/authenticated_http'

module ChefDK
  module Policyfile
    class ChefServerCookbookSource
      attr_reader :uri

      def initialize(uri)
        @uri = SourceURI.parse(uri)
        @http_connections = {}
        yield self if block_given?
      end

      def ==(other)
        other.kind_of?(self.class) && other.uri == uri
      end

      def universe_graph
        @universe_graph ||= begin
          full_chef_server_graph.inject({}) do |normalized_graph, (cookbook_name, metadata_by_version)|
            normalized_graph[cookbook_name] = metadata_by_version.inject({}) do |deps_by_version, (version, metadata)|
              deps_by_version[version] = metadata["dependencies"]
              deps_by_version
            end
            normalized_graph
          end
        end
      end

      def source_options_for(cookbook_name, cookbook_version)
        base_uri = full_chef_server_graph[cookbook_name][cookbook_version]['download_url']
        {
          chefserver: base_uri,
          version: cookbook_version,
          http_client: http_connection_for(base_uri)
        }
      end

      def null?
        false
      end

      def desc
        "chef_server(#{uri})"
      end

      private

      def http_connection_for(base_url)
        @http_connections[base_url] ||= ChefDK::AuthenticatedHTTP::Simple.new(base_url)
      end

      def full_chef_server_graph
        @full_chef_server_graph ||=
          begin
            graph_json = http_connection_for(uri.to_s).get('/universe')
            FFI_Yajl::Parser.parse(graph_json)
          end
      end
    end
  end
end
