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
  module Policyfile

    class RevIDLockDataMap

      attr_reader :policy_name
      attr_reader :lock_info_by_rev_id

      def initialize(policy_name, lock_info_by_rev_id)
        @policy_name = policy_name
        @lock_info_by_rev_id = lock_info_by_rev_id
      end

      def cb_info_for(rev_id, cookbook_name)
        lock = lock_info_by_rev_id[rev_id]
        cookbook_lock = lock["cookbook_locks"][cookbook_name]

        if cookbook_lock
          [cookbook_lock["version"], cookbook_lock["identifier"] ]
        else
          nil
        end
      end

      def cbs_with_differing_ids
        cbs_with_differing_ids = Set.new
        all_cookbook_names.each do |cookbook_name|
          all_identifiers = lock_info_by_rev_id.inject(Set.new) do |id_set, (_rev_id, rev_info)|
            cookbook_lock = rev_info["cookbook_locks"][cookbook_name]
            identifier = cookbook_lock && cookbook_lock["identifier"]
            id_set << identifier
          end
          cbs_with_differing_ids << cookbook_name if all_identifiers.size > 1
        end
        cbs_with_differing_ids
      end

      def all_cookbook_names
        lock_info_by_rev_id.inject(Set.new) do |cb_set, (_rev_id, rev_info)|
          cb_set.merge(rev_info["cookbook_locks"].keys)
        end
      end
    end

    class PolicyGroupRevIDMap

      include Enumerable

      attr_reader :policy_name
      attr_reader :revision_ids_by_group

      def initialize(policy_name, revision_ids_by_group)
        @policy_name = policy_name
        @revision_ids_by_group = revision_ids_by_group
      end

      def unique_revision_ids
        revision_ids_by_group.values.uniq
      end

      def policy_group_names
        revision_ids_by_group.keys
      end

      def max_group_name_length
        policy_group_names.map(&:size).max
      end

      def format_revision_ids
        revision_ids_by_group.inject({}) do |map, (group_name, rev_id)|
          map[group_name] = yield rev_id
          map
        end
      end

      def empty?
        policy_group_names.empty?
      end

      def each
        revision_ids_by_group.each do |group_name, rev_id|
          yield group_name, rev_id
        end
      end
    end

    class Lister

      attr_accessor :policy_lock_content

      attr_reader :config

      def initialize(config: nil)
        @config = config
        @policies_by_name = nil
        @policies_by_group = nil
        @policy_lock_content = {}
        @active_revisions = nil
      end

      # A Hash with the following format
      #   {
      #     "appserver" => {
      #       "1111111111111111111111111111111111111111111111111111111111111111" => {},
      #       "2222222222222222222222222222222222222222222222222222222222222222" => {}
      #     },
      def policies_by_name
        @policies_by_name || fetch_policy_lists
        @policies_by_name
      end

      # A Hash with the following format:
      #   "dev" => {
      #     "appserver" => "1111111111111111111111111111111111111111111111111111111111111111",
      #     "load-balancer" => "5555555555555555555555555555555555555555555555555555555555555555",
      #     "db" => "9999999999999999999999999999999999999999999999999999999999999999"
      #   }
      def policies_by_group
        @policies_by_group || fetch_policy_lists
        @policies_by_group
      end

      def revision_info_for(policy_name, _revision_id_list)
        RevIDLockDataMap.new(policy_name, policy_lock_content[policy_name])
      end

      def revision_ids_by_group_for_each_policy
        policies_by_name.each do |policy_name, _policies|
          rev_id_by_group = revision_ids_by_group_for(policy_name)
          yield policy_name, rev_id_by_group
        end
      end

      def revision_ids_by_group_for(policy_name)
        map = policies_by_group.inject({}) do |rev_id_map, (group_name, rev_id_map_for_group)|
          rev_id_map[group_name] = rev_id_map_for_group[policy_name]
          rev_id_map
        end
        PolicyGroupRevIDMap.new(policy_name, map)
      end

      def orphaned_revisions(policy_name)
        orphans = []
        policies_by_name[policy_name].each do |rev_id, _data|
          orphans << rev_id unless active_revisions.include?(rev_id)
        end
        orphans
      end

      def active_revisions
        @active_revisions ||= policies_by_group.inject(Set.new) do |set, (_group, policy_name_rev_id_map)|
          policy_name_rev_id_map.each do |policy_name, rev_id|
            set << rev_id
          end
          set
        end
      end

      def empty?
        policies_by_name.empty? && policies_by_group.empty?
      end

      def http_client
        @http_client ||= Chef::ServerAPI.new(config.chef_server_url,
                                                       signing_key_filename: config.client_key,
                                                       client_name: config.node_name)
      end

      # @api private
      # Sets internal copy of policyfile data to policies_by_name and
      # policies_by_group. Used for internal testing.
      def set!(policies_by_name, policies_by_group)
        @policies_by_name = policies_by_name
        @policies_by_group = policies_by_group
        @active_revisions = nil
      end

      private

      def fetch_policy_lists
        policy_list_data = http_client.get("policies")
        set_policies_by_name_from_api(policy_list_data)

        policy_group_data = http_client.get("policy_groups")
        set_policies_by_group_from_api(policy_group_data)
      end

      def set_policies_by_name_from_api(policy_list_data)
        @policies_by_name = policy_list_data.inject({}) do |map, (policy_name, policy_info)|
          map[policy_name] = policy_info["revisions"]
          map
        end
      end

      def set_policies_by_group_from_api(policy_group_data)
        @policies_by_group = policy_group_data.inject({}) do |map, (policy_group, policy_info)|
          map[policy_group] = (policy_info["policies"] || []).inject({}) do |rev_map, (policy_name, rev_info)|
            rev_map[policy_name] = rev_info["revision_id"]; rev_map
          end

          map
        end
      end

    end
  end
end
