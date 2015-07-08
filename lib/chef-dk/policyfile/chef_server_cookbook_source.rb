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

module ChefDK
  module Policyfile
    class ChefServerCookbookSource

      attr_reader :uri

      def initialize(uri)
        @uri = uri
      end

      def ==(other)
        other.kind_of?(self.class) && other.uri == uri
      end

      def universe_graph
        raise UnsupportedFeature, 'ChefDK does not support chef-server cookbook default sources at this time'
      end

      def source_options_for(cookbook_name, cookbook_version)
        raise UnsupportedFeature, 'ChefDK does not support chef-server cookbook default sources at this time'
      end

      def null?
        false
      end

      def desc
        "chef_server(#{uri})"
      end

    end
  end
end


