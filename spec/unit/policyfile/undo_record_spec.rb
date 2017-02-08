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

require "spec_helper"
require "chef-dk/policyfile/undo_record"

describe ChefDK::Policyfile::UndoRecord do

  subject(:undo_record) { described_class.new }

  let(:policy_revision) do
    {
      "name" => "appserver",
      "revision_id" => "1111111111111111111111111111111111111111111111111111111111111111",
    }
  end

  context "when empty" do

    it "has an empty description" do
      expect(undo_record.description).to eq("")
    end

    it "has an empty set of policy groups" do
      expect(undo_record.policy_groups).to eq([])
    end

    it "has an empty set of policy revisions" do
      expect(undo_record.policy_revisions).to eq([])
    end

    it "converts to a serializable data structure" do
      expected = {
        "format_version" => 1,
        "description" => "",
        "backup_data" => {
          "policy_groups" => [],
          "policy_revisions" => [],
        },
      }
      expect(undo_record.for_serialization).to eq(expected)
    end
  end

  context "with policy data" do

    before do
      undo_record.description = "delete-policy-group preprod"
      undo_record.add_policy_group("preprod")
      undo_record.add_policy_revision("appserver", "preprod", policy_revision)
    end

    it "has a description" do
      expect(undo_record.description).to eq("delete-policy-group preprod")
    end

    it "has a policy group" do
      expect(undo_record.policy_groups).to eq( [ "preprod" ] )
    end

    it "has a policy revision" do
      expect(undo_record.policy_revisions.size).to eq(1)
      revision_info = undo_record.policy_revisions.first
      expect(revision_info.policy_name).to eq("appserver")
      expect(revision_info.policy_group).to eq("preprod")
      expect(revision_info.data).to eq(policy_revision)
    end

    it "converts to a serializable data structure" do
      expected = {
        "format_version" => 1,
        "description" => "delete-policy-group preprod",
        "backup_data" => {
          "policy_groups" => [ "preprod" ],
          "policy_revisions" => [
            {
              "policy_name" => "appserver",
              "policy_group" => "preprod",
              "data" => policy_revision,
            },
          ],
        },
      }
      expect(undo_record.for_serialization).to eq(expected)
    end

  end

  describe "loading from serialized data" do

    context "with invalid data" do

      context "with an invalid object type" do

        let(:serialized_data) { [] }

        it "raises an error" do
          expect { undo_record.load(serialized_data) }.to raise_error(ChefDK::InvalidUndoRecord)
        end

      end

      context "when required top-level keys aren't present" do

        let(:serialized_data) { {} }

        it "raises an error" do
          expect { undo_record.load(serialized_data) }.to raise_error(ChefDK::InvalidUndoRecord)
        end

      end

      context "when backup_data is an invalid type" do

        let(:serialized_data) do
          {
            "format_version" => 1,
            "description" => "delete-policy-group preprod",
            "backup_data" => [],
          }
        end

        it "raises an error" do
          expect { undo_record.load(serialized_data) }.to raise_error(ChefDK::InvalidUndoRecord)
        end

      end

      context "when backup_data is missing required fields" do

        let(:serialized_data) do
          {
            "format_version" => 1,
            "description" => "delete-policy-group preprod",
            "backup_data" => {},
          }
        end

        it "raises an error" do
          expect { undo_record.load(serialized_data) }.to raise_error(ChefDK::InvalidUndoRecord)
        end

      end

      context "when backup_data has invalid policy_groups data" do

        let(:serialized_data) do
          {
            "format_version" => 1,
            "description" => "delete-policy-group preprod",
            "backup_data" => {
              "policy_groups" => nil,
              "policy_revisions" => [],
            },
          }
        end

        it "raises an error" do
          expect { undo_record.load(serialized_data) }.to raise_error(ChefDK::InvalidUndoRecord)
        end

      end

      context "when backup_data has and invalid type for policy_revisions" do

        let(:serialized_data) do
          {
            "format_version" => 1,
            "description" => "delete-policy-group preprod",
            "backup_data" => {
              "policy_groups" => [],
              "policy_revisions" => nil,
            },
          }
        end

        it "raises an error" do
          expect { undo_record.load(serialized_data) }.to raise_error(ChefDK::InvalidUndoRecord)
        end

      end

      context "when the backup_data has an invalid item in policy revisions" do

        let(:serialized_data) do
          {
            "format_version" => 1,
            "description" => "delete-policy-group preprod",
            "backup_data" => {
              "policy_groups" => [],
              "policy_revisions" => [ nil ],
            },
          }
        end

        it "raises an error" do
          expect { undo_record.load(serialized_data) }.to raise_error(ChefDK::InvalidUndoRecord)
        end

      end
    end

    context "with valid data" do
      let(:serialized_data) do
        {
          "format_version" => 1,
          "description" => "delete-policy-group preprod",
          "backup_data" => {
            "policy_groups" => [ "preprod" ],
            "policy_revisions" => [
              {
                "policy_name" => "appserver",
                "policy_group" => "preprod",
                "data" => policy_revision,
              },
            ],
          },
        }
      end

      before do
        undo_record.load(serialized_data)
      end

      it "has a policy group" do
        expect(undo_record.policy_groups).to eq( [ "preprod" ] )
      end

      it "has a policy revision" do
        expect(undo_record.policy_revisions.size).to eq(1)
        revision_info = undo_record.policy_revisions.first
        expect(revision_info.policy_name).to eq("appserver")
        expect(revision_info.policy_group).to eq("preprod")
        expect(revision_info.data).to eq(policy_revision)
      end

      it "converts to a serializable data structure" do
        expect(undo_record.for_serialization).to eq(serialized_data)
      end

    end
  end

end
