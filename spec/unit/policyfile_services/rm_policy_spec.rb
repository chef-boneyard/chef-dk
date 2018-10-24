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
require "chef-dk/policyfile_services/rm_policy"

describe ChefDK::PolicyfileServices::RmPolicy do

  let(:policy_name) { "appserver" }

  let(:http_client) { instance_double(Chef::ServerAPI) }

  let(:policy_revisions_data) do
    {
      "revisions" => {
        "2222222222222222222222222222222222222222222222222222222222222222" => {},
      },
    }
  end

  let(:ui) { TestHelpers::TestUI.new }

  let(:chef_config) do
    double("Chef::Config",
           chef_server_url: "https://localhost:10443",
           client_key: "/path/to/client/key.pem",
           node_name: "deuce")
  end

  subject(:rm_policy_service) do
    described_class.new(policy_name: policy_name, ui: ui, config: chef_config)
  end

  let(:undo_record) do
    rm_policy_service.undo_record
  end

  let(:undo_stack) do
    rm_policy_service.undo_stack
  end

  it "configures an HTTP client" do
    expect(Chef::ServerAPI).to receive(:new).with("https://localhost:10443",
                                                       signing_key_filename: "/path/to/client/key.pem",
                                                       client_name: "deuce")
    rm_policy_service.http_client
  end

  context "when the server returns an error fetching the policy data" do

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
      allow(rm_policy_service).to receive(:http_client).and_return(http_client)
    end

    describe "when getting an error fetching policy revisions" do

      before do
        expect(http_client).to receive(:get).with("/policies/appserver").and_return(policy_revisions_data)
        expect(http_client).to receive(:get)
          .with("/policies/appserver/revisions/2222222222222222222222222222222222222222222222222222222222222222")
          .and_raise(http_exception)
      end

      it "re-raises the error with a standardized exception class" do
        expect { rm_policy_service.run }.to raise_error(ChefDK::DeletePolicyError)
      end

    end

  end

  context "when the given policy doesn't exist" do

    let(:policy_group) { "incorrect_policy_group_name" }

    let(:response) do
      Net::HTTPResponse.send(:response_class, "404").new("1.0", "404", "Not Found").tap do |r|
        r.instance_variable_set(:@body, "not found")
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
      allow(rm_policy_service).to receive(:http_client).and_return(http_client)
      expect(http_client).to receive(:get).with("/policies/appserver").and_raise(http_exception)
    end

    it "prints a message stating that the policy doesn't exist" do
      expect { rm_policy_service.run }.to_not raise_error
      expect(ui.output).to eq("Policy 'appserver' does not exist on the server\n")
    end

  end

  # This case makes undo impossible to implement, because there are no APIs to
  # create a policy name without creating a revision (i.e., there is no
  # `POST /policies`). Because of the separation between CLI and service
  # objects, running `chef delete-policy empty-policy` will still tell the user
  # they can undo that action by running `chef undelete --last`, but that isn't
  # true. That said, a policy with no revisions is invisible to `chef-client`
  # and `chef show-policy`; the only way to create that state with the CLI is to
  # `chef delete-policy-group` all the groups that policy was applied to and
  # then run `chef clean-policy-revisions`, which can be undone by running
  # `chef undelete` multiple times. So we'll test this scenario to make sure we
  # don't crash, but not worry about the slightly incorrect behavior.
  context "when the policy exists but has no revisions" do

    let(:empty_policy_data) { {} }

    before do
      allow(rm_policy_service).to receive(:http_client).and_return(http_client)
      expect(http_client).to receive(:get).with("/policies/appserver").and_return(empty_policy_data)
      expect(http_client).to receive(:delete).with("/policies/appserver")

      expect(undo_stack).to receive(:push).with(undo_record)
    end

    it "removes the policy" do
      rm_policy_service.run
    end

  end

  context "when the policy has several revisions" do

    let(:policy_appserver_2) do
      {
        "name" => "appserver",
        "revision_id" => "2222222222222222222222222222222222222222222222222222222222222222",
      }
    end

    let(:policy_group_data) do
      {
        "dev" => {
          "uri" => "https://chef.example/organizations/testorg/policy_groups/dev",
        },
        "preprod" => {
          "uri" => "https://chef.example/organizations/testorg/policy_groups/preprod",
        },
      }
    end

    before do
      allow(rm_policy_service).to receive(:http_client).and_return(http_client)

      expect(http_client).to receive(:get).with("/policies/appserver").and_return(policy_revisions_data)
      expect(http_client).to receive(:get).with("/policy_groups").and_return(policy_group_data)

      expect(http_client).to receive(:get)
        .with("/policies/appserver/revisions/2222222222222222222222222222222222222222222222222222222222222222")
        .and_return(policy_appserver_2)
      expect(http_client).to receive(:delete).with("/policies/appserver")

      expect(undo_stack).to receive(:push).with(undo_record)
    end

    it "removes the policy" do
      rm_policy_service.run
      expect(ui.output).to include("Removed policy 'appserver'.")
    end

    it "stores the policy revisions in the restore file" do
      rm_policy_service.run

      expect(undo_record.description).to eq("delete-policy appserver")
      expect(undo_record.policy_groups).to eq( [ ] )
      expect(undo_record.policy_revisions.size).to eq(1)
      stored_revision_info = undo_record.policy_revisions.first
      expect(stored_revision_info.policy_group).to be_nil
      expect(stored_revision_info.policy_name).to eq("appserver")
      expect(stored_revision_info.data).to eq(policy_appserver_2)
    end

    context "and some policy revisions are associated to policy groups" do

      let(:policy_group_data) do
        {
          "dev" => {
            "uri" => "https://chef.example/organizations/testorg/policy_groups/dev",
            "policies" => {
              "appserver" => { "revision_id" => "2222222222222222222222222222222222222222222222222222222222222222" },
              "load-balancer" => { "revision_id" => "5555555555555555555555555555555555555555555555555555555555555555" },
              "db" => { "revision_id" => "9999999999999999999999999999999999999999999999999999999999999999" },
            },
          },
          "preprod" => {
            "uri" => "https://chef.example/organizations/testorg/policy_groups/preprod",
            "policies" => {
              "appserver" => { "revision_id" => "2222222222222222222222222222222222222222222222222222222222222222" },
              "load-balancer" => { "revision_id" => "5555555555555555555555555555555555555555555555555555555555555555" },
              "db" => { "revision_id" => "9999999999999999999999999999999999999999999999999999999999999999" },
            },
          },
          "prod" => {
            "uri" => "https://chef.example/organizations/testorg/policy_groups/prod",
            "policies" => {
              "appserver" => { "revision_id" => "1111111111111111111111111111111111111111111111111111111111111111" },
              "load-balancer" => { "revision_id" => "5555555555555555555555555555555555555555555555555555555555555555" },
              "db" => { "revision_id" => "9999999999999999999999999999999999999999999999999999999999999999" },
            },
          },
        }
      end

      it "maps the policy revisions to their groups in the restore file" do
        rm_policy_service.run

        expect(undo_record.description).to eq("delete-policy appserver")
        expect(undo_record.policy_groups).to eq( [ ] )
        expect(undo_record.policy_revisions.size).to eq(2)

        stored_revision_info_1 = undo_record.policy_revisions.first
        expect(stored_revision_info_1.policy_group).to eq("dev")
        expect(stored_revision_info_1.policy_name).to eq("appserver")
        expect(stored_revision_info_1.data).to eq(policy_appserver_2)

        stored_revision_info_2 = undo_record.policy_revisions.last
        expect(stored_revision_info_2.policy_group).to eq("preprod")
        expect(stored_revision_info_2.policy_name).to eq("appserver")
        expect(stored_revision_info_2.data).to eq(policy_appserver_2)
      end

    end

  end

end
