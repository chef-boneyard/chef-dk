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
require "chef-dk/policyfile/lister"

describe ChefDK::Policyfile::Lister do

  def api_url(org_specific_path)
    "https://chef.example/organizations/myorg/#{org_specific_path}"
  end

  let(:config) do
    double("Chef::Config",
           chef_server_url: "https://localhost:10443",
           client_key: "/path/to/client/key.pem",
           node_name: "deuce")
  end

  let(:http_client) { instance_double(Chef::ServerAPI) }

  subject(:info_fetcher) do
    described_class.new(config: config)
  end

  it "configures an HTTP client" do
    expect(Chef::ServerAPI).to receive(:new).with("https://localhost:10443",
                                                       signing_key_filename: "/path/to/client/key.pem",
                                                       client_name: "deuce")
    info_fetcher.http_client
  end

  context "when the data is fetched successfully from the server" do

    before do
      allow(info_fetcher).to receive(:http_client).and_return(http_client)

      allow(http_client).to receive(:get).with("policy_groups").and_return(policy_group_list_data)
      allow(http_client).to receive(:get).with("policies").and_return(policy_list_data)
    end

    context "when the server has no policies or groups" do

      let(:policy_group_list_data) { {} }
      let(:policy_list_data) { {} }

      it "gives a Hash of policy revisions by policy name" do
        expect(info_fetcher.policies_by_name).to eq({})
      end

      it "gives a Hash of policy revisions by policy group" do
        expect(info_fetcher.policies_by_group).to eq({})
      end

      it "is empty" do
        expect(info_fetcher).to be_empty
      end

      it "has no active revisions" do
        expect(info_fetcher.active_revisions).to be_empty
      end
    end

    context "when the server has policies and groups" do
      ##
      # Example API response data copied from oc-chef-pedant:

      let(:policy_list_data) do
        {
          "appserver" => {
            "uri" => api_url("policies/appserver"),
            "revisions" => {
              "1111111111111111111111111111111111111111" => {},
              "2222222222222222222222222222222222222222" => {},
              "3333333333333333333333333333333333333333" => {},
              "4444444444444444444444444444444444444444" => {},
            },
          },
          "db" => {
            "uri" => api_url("policies/db"),
            "revisions" => {
              "6666666666666666666666666666666666666666" => {},
              "7777777777777777777777777777777777777777" => {},
              "8888888888888888888888888888888888888888" => {},
              "9999999999999999999999999999999999999999" => {},
            },
          },
          "cache" => {
            "uri" => api_url("policies/cache"),
            "revisions" => {
              "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa" => {},
              "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb" => {},
            },
          },
        }
      end

      let(:dev_group_data) do
        {
          "uri" => api_url("policy_groups/dev"),
          "policies" => {
            "db" => { "revision_id" => "6666666666666666666666666666666666666666" },
            "appserver" => { "revision_id" => "1111111111111111111111111111111111111111" },
            "cache" => { "revision_id" => "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa" },
          },
        }
      end

      let(:test_group_data) do
        {
          "uri" => api_url("policy_groups/test"),
          "policies" => {
            "db" => { "revision_id" => "7777777777777777777777777777777777777777" },
            "appserver" => { "revision_id" => "2222222222222222222222222222222222222222" },
            "cache" => { "revision_id" => "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb" },
          },
        }
      end

      let(:prod_group_data) do
        {
          "uri" => api_url("policy_groups/prod"),
          "policies" => {
            "db" => { "revision_id" => "8888888888888888888888888888888888888888" },
            "appserver" => { "revision_id" => "3333333333333333333333333333333333333333" },
          },
        }
      end

      let(:policy_group_list_data) do
        {
          "dev" => dev_group_data,
          "test" => test_group_data,
          "prod" => prod_group_data,
        }
      end

      let(:expected_policy_list) do
        {
          "appserver" => {
            "1111111111111111111111111111111111111111" => {},
            "2222222222222222222222222222222222222222" => {},
            "3333333333333333333333333333333333333333" => {},
            "4444444444444444444444444444444444444444" => {},
          },
          "db" => {
            "6666666666666666666666666666666666666666" => {},
            "7777777777777777777777777777777777777777" => {},
            "8888888888888888888888888888888888888888" => {},
            "9999999999999999999999999999999999999999" => {},
          },
          "cache" => {
            "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa" => {},
            "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb" => {},
          },
        }
      end

      let(:expected_policy_group_list) do
        {
          "dev" => {
            "db" => "6666666666666666666666666666666666666666",
            "appserver" => "1111111111111111111111111111111111111111",
            "cache" => "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
          },
          "test" => {
            "db" => "7777777777777777777777777777777777777777",
            "appserver" => "2222222222222222222222222222222222222222",
            "cache" => "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb",
          },
          "prod" => {
            "db" => "8888888888888888888888888888888888888888",
            "appserver" => "3333333333333333333333333333333333333333",
          },
        }
      end

      it "gives a Hash of policy revisions by policy name" do
        expect(info_fetcher.policies_by_name).to eq(expected_policy_list)
      end

      it "gives a Hash of policy revisions by policy group" do
        expect(info_fetcher.policies_by_group).to eq(expected_policy_group_list)
      end

      it "is not empty" do
        expect(info_fetcher).to_not be_empty
      end

      it "lists active revisions" do
        expected_active_revisions = expected_policy_group_list.values.map(&:values).flatten

        expected_active_revisions_set = Set.new(expected_active_revisions)
        expect(info_fetcher.active_revisions).to eq(expected_active_revisions_set)
      end

      it "lists orphaned revisions for a given policy" do
        expect(info_fetcher.orphaned_revisions("db")).to eq(%w{ 9999999999999999999999999999999999999999 })
        expect(info_fetcher.orphaned_revisions("appserver")).to eq(%w{ 4444444444444444444444444444444444444444 })
        expect(info_fetcher.orphaned_revisions("cache")).to eq([])
      end

      it "yields revision ids by group" do
        map = {}

        info_fetcher.revision_ids_by_group_for_each_policy do |policy_name, rev_id_by_group|
          map[policy_name] = rev_id_by_group
        end

        appserver_rev_ids = {
          "dev" => "1111111111111111111111111111111111111111",
          "test" => "2222222222222222222222222222222222222222",
          "prod" => "3333333333333333333333333333333333333333",
        }

        expect(map["appserver"].revision_ids_by_group).to eq(appserver_rev_ids)

        db_rev_ids = {
          "dev" => "6666666666666666666666666666666666666666",
          "test" => "7777777777777777777777777777777777777777",
          "prod" => "8888888888888888888888888888888888888888",
        }

        expect(map["db"].revision_ids_by_group).to eq(db_rev_ids)

        cache_rev_ids = {
          "dev" => "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
          "test" => "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb",
          "prod" => nil,
        }
        expect(map["cache"].revision_ids_by_group).to eq(cache_rev_ids)
      end

      context "when the server has an empty group" do

        let(:dev_group_data) do
          {
            "uri" => api_url("policy_groups/dev"),
          }
        end

        # Regression test: this exercises the case where the policy group data
        # from the server has no "policies" key, which previously caused a NoMethodError.
        it "correctly lists groups without policies" do
          expect(info_fetcher.policies_by_group["dev"]).to eq({})
        end

      end

    end

  end

end
