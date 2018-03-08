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

module ChefDK
  module Policyfile
    class NullCookbookSource

      def initialize(_uri = nil)
      end

      def universe_graph
        {}
      end

      def source_options_for(cookbook_name, cookbook_version)
        raise UnsupportedFeature, "You must set a default_source in your Policyfile to download cookbooks without explicit sources"
      end

      def null?
        true
      end

      def preferred_cookbooks
        []
      end

      def desc
        "null_cookbook_source"
      end

    end
  end
end
