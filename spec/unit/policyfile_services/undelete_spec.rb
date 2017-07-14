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
require "chef-dk/policyfile_services/undelete"

describe ChefDK::PolicyfileServices::Undelete do

  let(:chef_config) { double("Chef::Config") }

  let(:ui) { TestHelpers::TestUI.new }

  let(:policy_name) { nil }

  let(:policy_group) { nil }

  let(:show_orphans) { false }

  let(:summary_diff) { false }

  let(:undo_dir) { tempdir }

  let(:undo_record_id) { nil }

  subject(:undelete_service) do
    described_class.new(config: chef_config,
                        ui: ui,
                        undo_record_id: undo_record_id)
  end

  describe "listing undo operations" do

    before do
      allow(undelete_service.undo_stack).to receive(:undo_dir).and_return(undo_dir)
    end

    after do
      clear_tempdir
    end

    context "when the undo dir doesn't exist" do

      let(:undo_dir) { File.join(tempdir, "this", "isnt", "here") }

      it "prints a message saying there aren't any things to undo to stderr" do
        undelete_service.list
        expect(ui.output).to eq("Nothing to undo.\n")
      end

    end

    context "when the undo dir exists, but it empty" do

      it "prints a message saying there aren't any things to undo to stderr" do
        undelete_service.list
        expect(ui.output).to eq("Nothing to undo.\n")
      end

    end

    context "when the undo dir exists and there are undo records in it" do

      let(:policy_revision) do
        {
          "name" => "appserver",
          "revision_id" => "1111111111111111111111111111111111111111111111111111111111111111",
        }
      end

      let(:undo_record1) do
        ChefDK::Policyfile::UndoRecord.new.tap do |undo_record|
          undo_record.description = "delete-policy-group example1"
          undo_record.add_policy_group("example1")
          undo_record.add_policy_revision("appserver", "example1", policy_revision)
        end
      end

      let(:undo_record2) do
        ChefDK::Policyfile::UndoRecord.new.tap do |undo_record|
          undo_record.description = "delete-policy-group example2"
          undo_record.add_policy_group("example2")
          undo_record.add_policy_revision("appserver", "example2", policy_revision)
        end
      end

      let(:undo_record3) do
        ChefDK::Policyfile::UndoRecord.new.tap do |undo_record|
          undo_record.description = "delete-policy-group example3"
          undo_record.add_policy_group("example3")
          undo_record.add_policy_revision("appserver", "example3", policy_revision)
        end
      end

      # `Time.new` is stubbed later on, need to force it to be evaluated before
      # then.
      let!(:start_time) { Time.new }

      def next_time
        @increment ||= 0
        @increment += 1

        start_time + @increment
      end

      let(:times) { [] }

      before do
        allow(Time).to receive(:new) do
          t = next_time
          times << t
          t
        end
        undo_stack = ChefDK::Policyfile::UndoStack.new
        allow(undo_stack).to receive(:undo_dir).and_return(undo_dir)
        undo_stack.push(undo_record1).push(undo_record2).push(undo_record3)
      end

      it "prints the items in reverse chronological order" do
        undelete_service.list

        timestamps = times.map { |t| t.utc.strftime("%Y%m%d%H%M%S") }

        expected_output = <<-OUTPUT
#{timestamps[2]}: delete-policy-group example3
#{timestamps[1]}: delete-policy-group example2
#{timestamps[0]}: delete-policy-group example1
OUTPUT
        expect(ui.output).to eq(expected_output)
      end

    end

  end

  describe "undoing a policy group delete" do

    let(:policy_revision) do
      {
        "name" => "appserver",
        "revision_id" => "1111111111111111111111111111111111111111111111111111111111111111",
      }
    end

    let(:undo_record1) do
      ChefDK::Policyfile::UndoRecord.new.tap do |undo_record|
        undo_record.description = "delete-policy-group example1"
        undo_record.add_policy_group("example1")
        undo_record.add_policy_revision("appserver", "example1", policy_revision)
      end
    end

    let(:undo_stack) do
      instance_double(ChefDK::Policyfile::UndoStack).tap do |s|
        allow(s).to receive(:pop).and_yield(undo_record1)
      end
    end

    let(:http_client) { instance_double(Chef::ServerAPI) }

    before do
      allow(undelete_service).to receive(:http_client).and_return(http_client)
      allow(undelete_service).to receive(:undo_stack).and_return(undo_stack)
    end

    describe "when an error occurs posting data to the server" do

      let(:response) do
        Net::HTTPResponse.send(:response_class, "500").new("1.0", "500", "Internal Server Error").tap do |r|
          r.instance_variable_set(:@body, "oops")
        end
      end

      let(:http_exception) do
        begin
          response.error!
        rescue => e
          e
        end
      end

      before do
        expect(http_client).to receive(:put).
          with("/policy_groups/example1/policies/appserver", policy_revision).
          and_raise(http_exception)
      end

      it "raises an error" do
        expect { undelete_service.run }.to raise_error(ChefDK::UndeleteError)
      end

    end

    context "when the undelete is successful" do

      before do
        expect(http_client).to receive(:put).
          with("/policy_groups/example1/policies/appserver", policy_revision)
      end

      it "uploads all policies to the server" do
        undelete_service.run
        expect(ui.output).to eq("Restored policy 'appserver'\nRestored policy group 'example1'\n")
      end

    end

    context "when given a specific undo record id to undo" do

      let(:undo_record_id) { "20150827172127" }

      context "and the id doesn't exist" do

        before do
          expect(undo_stack).to receive(:has_id?).with(undo_record_id).and_return(false)
        end

        it "prints an error message that the id doesn't exist" do
          undelete_service.run
          expect(ui.output).to eq("No undo record with id '#{undo_record_id}' exists\n")
        end

      end

      context "and the id exists" do
        before do
          expect(undo_stack).to receive(:has_id?).with(undo_record_id).and_return(true)
          expect(undo_stack).to receive(:delete).with(undo_record_id).and_yield(undo_record1)
          expect(http_client).to receive(:put).
            with("/policy_groups/example1/policies/appserver", policy_revision)
        end

        it "uploads all policies to the server" do
          undelete_service.run
          expect(ui.output).to eq("Restored policy 'appserver'\nRestored policy group 'example1'\n")
        end

      end

    end

  end

  describe "undoing a policy delete" do

    let(:policy_revision) do
      {
        "name" => "appserver",
        "revision_id" => "1111111111111111111111111111111111111111111111111111111111111111",
      }
    end

    let(:undo_record1) do
      ChefDK::Policyfile::UndoRecord.new.tap do |undo_record|
        undo_record.description = "delete-policy-group example1"
        undo_record.add_policy_revision("appserver", nil, policy_revision)
      end
    end

    let(:undo_stack) do
      instance_double(ChefDK::Policyfile::UndoStack).tap do |s|
        allow(s).to receive(:pop).and_yield(undo_record1)
      end
    end

    let(:http_client) { instance_double(Chef::ServerAPI) }

    before do
      allow(undelete_service).to receive(:http_client).and_return(http_client)
      allow(undelete_service).to receive(:undo_stack).and_return(undo_stack)
    end

    context "when the revision to create doesn't exist" do

      before do
        expect(http_client).to receive(:post).
          with("/policies/appserver/revisions", policy_revision)
      end

      it "uploads all policies to the server" do
        undelete_service.run
        expect(ui.output).to eq("Restored policy 'appserver'\n")
      end

    end

  end

end
