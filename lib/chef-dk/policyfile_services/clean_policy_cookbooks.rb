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

require "set"

require "chef/server_api"
require "chef-dk/service_exceptions"

module ChefDK
  module PolicyfileServices

    class CleanPolicyCookbooks

      attr_reader :chef_config

      attr_reader :ui

      def initialize(config: nil, ui: nil)
        @chef_config = config
        @ui = ui

        @all_cookbooks = nil
        @active_cookbooks = nil
        @all_policies = nil
      end

      def run
        gc_cookbooks
      rescue => e
        raise PolicyCookbookCleanError.new("Failed to cleanup policy cookbooks", e)
      end

      def gc_cookbooks
        cookbooks = cookbooks_to_clean

        if cookbooks.empty?
          ui.msg("No cookbooks deleted.")
        end

        cookbooks.each do |name, identifiers|
          identifiers.each do |identifier|
            http_client.delete("/cookbook_artifacts/#{name}/#{identifier}")
            ui.msg("DELETE #{name} #{identifier}")
          end
        end
      end

      def all_cookbooks
        cookbook_list = http_client.get("/cookbook_artifacts")
        cookbook_list.inject({}) do |cb_map, (name, cb_info)|
          cb_map[name] = cb_info["versions"].map { |v| v["identifier"] }
          cb_map
        end
      end

      def active_cookbooks
        policy_revisions_by_name.inject({}) do |cb_map, (policy_name, revision_ids)|
          revision_ids.each do |revision_id|
            cookbook_revisions_in_policy(policy_name, revision_id).each do |cb_name, identifier|
              cb_map[cb_name] ||= Set.new
              cb_map[cb_name] << identifier
            end
          end
          cb_map
        end
      end

      def cookbooks_to_clean
        active_cbs = active_cookbooks

        all_cookbooks.inject({}) do |cb_map, (cb_name, revisions)|
          active_revs = active_cbs[cb_name] || Set.new
          inactive_revs = Set.new(revisions) - active_revs
          cb_map[cb_name] = inactive_revs unless inactive_revs.empty?

          cb_map
        end
      end

      # @api private
      def policy_revisions_by_name
        policies_list = http_client.get("/policies")
        policies_list.inject({}) do |policies_map, (name, policy_info)|
          policies_map[name] = policy_info["revisions"].keys
          policies_map
        end
      end

      # @api private
      def cookbook_revisions_in_policy(name, revision_id)
        policy_revision_data = http_client.get("/policies/#{name}/revisions/#{revision_id}")

        policy_revision_data["cookbook_locks"].inject({}) do |cb_map, (cb_name, lock_info)|
          cb_map[cb_name] = lock_info["identifier"]
          cb_map
        end
      end

      # @api private
      # An instance of Chef::ServerAPI configured with the user's
      # server URL and credentials.
      def http_client
        @http_client ||= Chef::ServerAPI.new(chef_config.chef_server_url,
                                             signing_key_filename: chef_config.client_key,
                                             client_name: chef_config.node_name)
      end
    end
  end
end
