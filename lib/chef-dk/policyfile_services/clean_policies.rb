#
# Copyright:: Copyright (c) 2015 Chef Software Inc.
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
require "chef-dk/service_exceptions"
require "chef-dk/policyfile/lister"

module ChefDK
  module PolicyfileServices
    class CleanPolicies

      Orphan = Struct.new(:policy_name, :revision_id)

      attr_reader :chef_config
      attr_reader :ui

      def initialize(config: nil, ui: nil)
        @chef_config = config
        @ui = ui
      end

      def run
        revisions_to_remove = orphaned_policies

        if revisions_to_remove.empty?
          ui.err("No policy revisions deleted")
          return true
        end

        results = revisions_to_remove.map do |policy|
          [ remove_policy(policy), policy ]
        end

        failures = results.select { |result, _policy| result.kind_of?(Exception) }

        unless failures.empty?
          details = failures.map do |result, policy|
            "- #{policy.policy_name} (#{policy.revision_id}): #{result.class} #{result}"
          end

          message = "Failed to delete some policy revisions:\n" + details.join("\n") + "\n"

          raise PolicyfileCleanError.new(message, MultipleErrors.new("multiple errors"))
        end

        true
      end

      def orphaned_policies
        policy_lister.policies_by_name.keys.inject([]) do |orphans, policy_name|
          orphans + policy_lister.orphaned_revisions(policy_name).map do |revision_id|
            Orphan.new(policy_name, revision_id)
          end
        end
      rescue => e
        raise PolicyfileCleanError.new("Failed to list policies for cleaning.", e)
      end

      def policy_lister
        @policy_lister ||= Policyfile::Lister.new(config: chef_config)
      end

      def http_client
        @http_client ||= Chef::ServerAPI.new(chef_config.chef_server_url,
                                               signing_key_filename: chef_config.client_key,
                                               client_name: chef_config.node_name)
      end

      private

      def remove_policy(policy)
        ui.msg("DELETE #{policy.policy_name} #{policy.revision_id}")
        http_client.delete("/policies/#{policy.policy_name}/revisions/#{policy.revision_id}")
        :ok
      rescue => e
        e
      end

    end
  end
end
