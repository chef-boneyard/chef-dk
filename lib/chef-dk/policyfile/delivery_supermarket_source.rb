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

require "forwardable"

require "semverse"

require "chef-dk/policyfile/community_cookbook_source"

module ChefDK
  module Policyfile

    # Fetches cookbooks from a supermarket, similar to CommunityCookbookSource
    # (which it delegates to), except that only the latest versions of any
    # cookbook can be used.
    #
    # This is intended to be used in an environment where the team wants to
    # make only the newest version of a given cookbook available in order to
    # force developers to integrate continuously at the component artifact
    # (cookbook) level. To achieve this goal, two constraints must be imposed:
    #
    # * Cookbook changes pass through a Ci pipeline and are ultimately uploaded
    #   to a private supermarket (or equivalent, i.e. mini-mart) after final
    #   approval (which can be automated or not)
    # * Version numbers for cookbooks that pass through the Ci pipeline always
    #   increase over time (so that largest version number == newest)
    #
    # In the future, alternative approaches may be persued to achieve the goal
    # of continuously integrating at the cookbook level without imposing those
    # constraints.
    #
    class DeliverySupermarketSource

      extend Forwardable

      def_delegator :@community_source, :uri
      def_delegator :@community_source, :source_options_for
      def_delegator :@community_source, :null?
      def_delegator :@community_source, :preferred_cookbooks
      def_delegator :@community_source, :preferred_source_for?
      def_delegator :@community_source, :preferred_for

      def initialize(uri)
        @community_source = CommunityCookbookSource.new(uri)
        yield self if block_given?
      end

      def ==(other)
        other.kind_of?(self.class) && other.uri == uri
      end

      def default_source_args
        [:delivery_supermarket, uri]
      end

      def universe_graph
        @universe_graph ||= begin
          @community_source.universe_graph.inject({}) do |truncated, (cookbook_name, version_and_deps_list)|
            sorted_versions = version_and_deps_list.keys.sort_by do |version_string|
              Semverse::Version.new(version_string)
            end
            greatest_version = sorted_versions.last
            truncated[cookbook_name] = { greatest_version => version_and_deps_list[greatest_version] }
            truncated
          end
        end
      end

      def desc
        "delivery_supermarket(#{uri})"
      end

    end
  end
end
