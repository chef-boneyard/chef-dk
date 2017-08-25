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

require "chef/server_api"
require "chef-dk/service_exceptions"
require "chef-dk/policyfile/undo_stack"

module ChefDK
  module PolicyfileServices
    class Undelete

      attr_reader :ui

      attr_reader :chef_config

      attr_reader :undo_record_id

      def initialize(undo_record_id: nil, config: nil, ui: nil)
        @chef_config = config
        @ui = ui
        @undo_record_id = undo_record_id

        @http_client = nil
        @undo_stack = nil
      end

      # In addition to the #run method, this class also has #list as a public
      # entry point. This prints the list of undoable items, with descriptions.
      def list
        if undo_stack.empty?
          ui.err("Nothing to undo.")
        else
          messages = []
          undo_stack.each_with_id do |timestamp, undo_record|
            messages.unshift("#{timestamp}: #{undo_record.description}")
          end
          messages.each { |m| ui.msg(m) }
        end
      end

      def run
        if undo_record_id
          if undo_stack.has_id?(undo_record_id)
            undo_stack.delete(undo_record_id) { |undo_record| restore(undo_record) }
          else
            ui.err("No undo record with id '#{undo_record_id}' exists")
          end
        else
          undo_stack.pop { |undo_record| restore(undo_record) }
        end
      rescue => e
        raise UndeleteError.new("Failed to undelete.", e)
      end

      def undo_stack
        @undo_stack ||= Policyfile::UndoStack.new
      end

      def http_client
        @http_client ||= Chef::ServerAPI.new(chef_config.chef_server_url,
                                                       signing_key_filename: chef_config.client_key,
                                                       client_name: chef_config.node_name)
      end

      private

      def restore(undo_record)
        undo_record.policy_revisions.each do |policy_info|
          if policy_info.policy_group.nil?
            recreate_as_orphan(policy_info)
          else
            recreate_and_associate_to_group(policy_info)
          end
        end
        if ( restored_policy_group = undo_record.policy_groups.first )
          ui.msg("Restored policy group '#{restored_policy_group}'")
        end
      end

      def recreate_as_orphan(policy_info)
        rel_uri = "/policies/#{policy_info.policy_name}/revisions"
        http_client.post(rel_uri, policy_info.data)
        ui.msg("Restored policy '#{policy_info.policy_name}'")
      end

      def recreate_and_associate_to_group(policy_info)
        rel_uri = "/policy_groups/#{policy_info.policy_group}/policies/#{policy_info.policy_name}"
        http_client.put(rel_uri, policy_info.data)
        ui.msg("Restored policy '#{policy_info.policy_name}'")
      end

    end
  end
end
