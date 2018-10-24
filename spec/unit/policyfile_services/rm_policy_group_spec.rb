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
require "chef-dk/policyfile_services/rm_policy_group"

describe ChefDK::PolicyfileServices::RmPolicyGroup do

  let(:policy_group) { "preprod" }

  let(:http_client) { instance_double(Chef::ServerAPI) }

  let(:ui) { TestHelpers::TestUI.new }

  let(:non_empty_policy_groups) do
    {
      "dev" => {
        "uri" => "https://chef.example/organizations/testorg/policy_groups/dev",
        "policies" => {
          "appserver" => { "revision_id" => "1111111111111111111111111111111111111111111111111111111111111111" },
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
    }
  end

  let(:empty_policy_groups) do
    {
      "dev" => {
        "uri" => "https://chef.example/organizations/testorg/policy_groups/dev",
      },
      "preprod" => {
        "uri" => "https://chef.example/organizations/testorg/policy_groups/preprod",
      },
    }
  end

  let(:chef_config) do
    double("Chef::Config",
           chef_server_url: "https://localhost:10443",
           client_key: "/path/to/client/key.pem",
           node_name: "deuce")
  end

  subject(:rm_policy_group_service) do
    described_class.new(policy_group: policy_group, ui: ui, config: chef_config)
  end

  let(:undo_record) do
    rm_policy_group_service.undo_record
  end

  let(:undo_stack) do
    rm_policy_group_service.undo_stack
  end

  it "configures an HTTP client" do
    expect(Chef::ServerAPI).to receive(:new).with("https://localhost:10443",
                                                       signing_key_filename: "/path/to/client/key.pem",
                                                       client_name: "deuce")
    rm_policy_group_service.http_client
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
      allow(rm_policy_group_service).to receive(:http_client).and_return(http_client)
    end

    describe "when getting an error response fetching the policy group" do

      before do
        expect(http_client).to receive(:get).with("/policy_groups").and_raise(http_exception)
      end

      it "re-raises the error with a standardized exception class" do
        expect { rm_policy_group_service.run }.to raise_error(ChefDK::DeletePolicyGroupError)
      end

    end

    describe "when getting an error fetching policy revisions" do

      before do
        expect(http_client).to receive(:get).with("/policy_groups").and_return(non_empty_policy_groups)
        expect(http_client).to receive(:get)
          .with("/policies/appserver/revisions/2222222222222222222222222222222222222222222222222222222222222222")
          .and_raise(http_exception)
      end

      it "re-raises the error with a standardized exception class" do
        expect { rm_policy_group_service.run }.to raise_error(ChefDK::DeletePolicyGroupError)
      end

    end

  end

  context "when the given group doesn't exist" do

    let(:policy_group) { "incorrect_policy_group_name" }

    before do
      allow(rm_policy_group_service).to receive(:http_client).and_return(http_client)
      expect(http_client).to receive(:get).with("/policy_groups").and_return(non_empty_policy_groups)
    end

    it "prints a message stating that the group doesn't exist" do
      expect { rm_policy_group_service.run }.to_not raise_error
      expect(ui.output).to eq("Policy group 'incorrect_policy_group_name' does not exist on the server\n")
    end

  end

  context "when the group exists but has no policies assigned to it" do

    before do
      allow(rm_policy_group_service).to receive(:http_client).and_return(http_client)
      expect(http_client).to receive(:get).with("/policy_groups").and_return(empty_policy_groups)
      expect(http_client).to receive(:delete).with("/policy_groups/preprod")
      expect(undo_stack).to receive(:push).with(undo_record)
    end

    it "removes the group" do
      rm_policy_group_service.run
      expect(ui.output).to include("Removed policy group 'preprod'.")
    end

    it "stores the group in the restore file" do
      rm_policy_group_service.run
      expect(undo_record.description).to eq("delete-policy-group preprod")
      expect(undo_record.policy_groups).to eq( [ policy_group ] )
      expect(undo_record.policy_revisions).to be_empty
    end

  end

  context "when the group exists and has policies assigned to it" do

    let(:policy_appserver_2) do
      {
        "name" => "appserver",
        "revision_id" => "2222222222222222222222222222222222222222222222222222222222222222",
      }
    end

    let(:policy_load_balancer_5) do
      {
        "name" => "load-balancer",
        "revision_id" => "5555555555555555555555555555555555555555555555555555555555555555",
      }
    end

    let(:policy_db_9) do
      {
        "name" => "db",
        "revision_id" => "9999999999999999999999999999999999999999999999999999999999999999",
      }
    end

    before do
      allow(rm_policy_group_service).to receive(:http_client).and_return(http_client)
      expect(http_client).to receive(:get).with("/policy_groups").and_return(non_empty_policy_groups)
      expect(http_client).to receive(:get)
        .with("/policies/appserver/revisions/2222222222222222222222222222222222222222222222222222222222222222")
        .and_return(policy_appserver_2)
      expect(http_client).to receive(:get)
        .with("/policies/load-balancer/revisions/5555555555555555555555555555555555555555555555555555555555555555")
        .and_return(policy_load_balancer_5)
      expect(http_client).to receive(:get)
        .with("/policies/db/revisions/9999999999999999999999999999999999999999999999999999999999999999")
        .and_return(policy_db_9)

      expect(http_client).to receive(:delete).with("/policy_groups/preprod")
      expect(undo_stack).to receive(:push).with(undo_record)
    end

    it "removes the group" do
      rm_policy_group_service.run
      expect(ui.output).to include("Removed policy group 'preprod'.")
    end

    it "stores the group and policyfile revision contents in the restore file" do
      rm_policy_group_service.run
      expect(undo_record.description).to eq("delete-policy-group preprod")
      expect(undo_record.policy_groups).to eq( [ policy_group ] )

      expected_policy_revision_undo_data =
        [
          { policy_name: "appserver", policy_group: "preprod", data: policy_appserver_2 },
          { policy_name: "load-balancer", policy_group: "preprod", data: policy_load_balancer_5 },
          { policy_name: "db", policy_group: "preprod", data: policy_db_9 },
        ]

      expect(undo_record.policy_revisions.map(&:to_h)).to match_array(expected_policy_revision_undo_data)
    end

  end

end
