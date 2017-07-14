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

require "chef-dk/service_exceptions"
require "chef/server_api"
require "chef-dk/policyfile/undo_stack"
require "chef-dk/policyfile/undo_record"

module ChefDK
  module PolicyfileServices

    class RmPolicy

      attr_reader :policy_name

      # @api private
      attr_reader :chef_config

      # @api private
      attr_reader :ui

      # @api private
      attr_reader :undo_record

      # @api private
      attr_reader :undo_stack

      def initialize(config: nil, ui: nil, policy_name: nil)
        @chef_config = config
        @ui = ui
        @policy_name = policy_name

        @policy_revision_data = nil
        @policy_exists = false
        @policy_group_data = nil

        @undo_record = Policyfile::UndoRecord.new
        @undo_stack = Policyfile::UndoStack.new
      end

      def run
        unless policy_exists?
          ui.err("Policy '#{policy_name}' does not exist on the server")
          return false
        end

        undo_record.description = "delete-policy #{policy_name}"

        unless policy_has_no_revisions?
          gather_policy_data_for_undo
        end

        http_client.delete("/policies/#{policy_name}")
        undo_stack.push(undo_record)
        ui.err("Removed policy '#{policy_name}'.")
      rescue => e
        raise DeletePolicyError.new("Failed to delete policy '#{policy_name}'", e)
      end

      # @api private
      # An instance of Chef::ServerAPI configured with the user's
      # server URL and credentials.
      def http_client
        @http_client ||= Chef::ServerAPI.new(chef_config.chef_server_url,
                                             signing_key_filename: chef_config.client_key,
                                             client_name: chef_config.node_name)
      end

      private

      def policy_has_no_revisions?
        policy_revision_data.empty? || policy_revision_data["revisions"].empty?
      end

      def gather_policy_data_for_undo
        revisions = policy_revision_data["revisions"].keys

        revisions.each do |revision_id|
          policy_revision_data = http_client.get("/policies/#{policy_name}/revisions/#{revision_id}")
          policy_groups = policy_groups_using_revision(revision_id)
          if policy_groups.empty?
            undo_record.add_policy_revision(policy_name, nil, policy_revision_data)
          else
            policy_groups.each do |policy_group|
              undo_record.add_policy_revision(policy_name, policy_group, policy_revision_data)
            end
          end
        end
      end

      def policy_groups_using_revision(revision_id)
        groups = []
        policy_group_data.each do |group_name, group_info|
          next unless group_info.key?("policies") && !group_info["policies"].empty?
          next unless group_info["policies"].key?(policy_name)
          next unless group_info["policies"][policy_name]["revision_id"] == revision_id
          groups << group_name if group_info
        end
        groups
      end

      def policy_group_data
        @policy_group_data ||= http_client.get("/policy_groups")
      end

      def policy_exists?
        return true if @policy_exists
        fetch_policy_revision_data
        @policy_exists
      end

      def policy_revision_data
        return @policy_revision_data if @policy_exists
        fetch_policy_revision_data
      end

      def fetch_policy_revision_data
        @policy_revision_data = http_client.get("/policies/#{policy_name}")
        @policy_exists = true
      rescue Net::HTTPServerException => e
        raise unless e.response.code == "404"
        @policy_exists = false
      end

    end
  end
end
