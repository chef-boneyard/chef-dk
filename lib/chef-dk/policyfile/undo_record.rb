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

module ChefDK
  module Policyfile

    class UndoRecord

      PolicyGroupRestoreData = Struct.new(:policy_name, :policy_group, :data) do

        def load(data)
          self.policy_name = data["policy_name"]
          self.policy_group = data["policy_group"]
          self.data = data["data"]
          self
        end

        def for_serialization
          {
            "policy_name" => policy_name,
            "policy_group" => policy_group,
            "data" => data,
          }
        end

      end

      attr_reader :policy_groups

      attr_reader :policy_revisions

      attr_accessor :description

      def initialize
        reset!
      end

      def ==(other)
        other.kind_of?(UndoRecord) &&
          other.policy_groups == policy_groups &&
          other.policy_revisions == policy_revisions
      end

      def add_policy_group(name)
        @policy_groups << name
      end

      def add_policy_revision(policy_name, policy_group, data)
        @policy_revisions << PolicyGroupRestoreData.new(policy_name, policy_group, data)
      end

      def load(data)
        reset!

        unless data.kind_of?(Hash)
          raise InvalidUndoRecord, "Undo data is incorrectly formatted. Must be a Hash, got '#{data}'."
        end
        missing_fields = %w{ format_version description backup_data }.select { |key| !data.key?(key) }
        unless missing_fields.empty?
          raise InvalidUndoRecord, "Undo data is missing mandatory field(s) #{missing_fields.join(', ')}. Undo data: '#{data}'"
        end

        @description = data["description"]

        policy_data = data["backup_data"]
        unless policy_data.kind_of?(Hash)
          raise InvalidUndoRecord, "'backup_data' in the undo record is incorrectly formatted. Must be a Hash, got '#{policy_data}'"
        end
        missing_policy_data_fields = %w{ policy_groups policy_revisions }.select { |key| !policy_data.key?(key) }
        unless missing_policy_data_fields.empty?
          raise InvalidUndoRecord,
            "'backup_data' in the undo record is missing mandatory field(s) #{missing_policy_data_fields.join(', ')}. Backup data: #{policy_data}"
        end

        policy_groups = policy_data["policy_groups"]

        unless policy_groups.kind_of?(Array)
          raise InvalidUndoRecord,
            "'policy_groups' data in the undo record is incorrectly formatted. Must be an Array, got '#{policy_groups}'"
        end

        @policy_groups = policy_groups

        policy_revisions = policy_data["policy_revisions"]
        unless policy_revisions.kind_of?(Array)
          raise InvalidUndoRecord,
            "'policy_revisions' data in the undo record is incorrectly formatted. Must be an Array, got '#{policy_revisions}'"
        end

        policy_revisions.each do |revision|
          unless revision.kind_of?(Hash)
            raise InvalidUndoRecord,
              "Invalid item in 'policy_revisions' in the undo record. Must be a Hash, got '#{revision}'"
          end

          @policy_revisions << PolicyGroupRestoreData.new.load(revision)
        end

        self
      end

      def for_serialization
        {
          "format_version" => 1,
          "description" => description,
          "backup_data" => {
            "policy_groups" => policy_groups,
            "policy_revisions" => policy_revisions.map(&:for_serialization),
          },
        }
      end

      private

      def reset!
        @description = ""
        @policy_groups = []
        @policy_revisions = []
      end

    end
  end
end
