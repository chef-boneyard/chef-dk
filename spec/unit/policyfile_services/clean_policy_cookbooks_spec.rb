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
require "chef-dk/policyfile_services/clean_policy_cookbooks"

describe ChefDK::PolicyfileServices::CleanPolicyCookbooks do

  let(:cookbook_artifacts_list) do
    {
      "mysql" => {
        "versions" => [
          {
            "identifier" => "6b506252cae939c874bd59b560c339b01c31326b",
          },
        ],
      },
      "build-essential" => {
        "versions" => [
          {
            "identifier" => "2db3df121028894f45497f847de91b91fbf76824",
          },
          {
            "identifier" => "d8ce58401d154378599b0fead81d2c390615602b",
          },
        ],
      },
    }
  end

  let(:cookbook_ids_by_name) do
    {
      "mysql" => [ "6b506252cae939c874bd59b560c339b01c31326b" ],
      "build-essential" => %w{2db3df121028894f45497f847de91b91fbf76824 d8ce58401d154378599b0fead81d2c390615602b},
    }
  end

  let(:cookbook_ids_in_sets_by_name) do
    cookbook_ids_by_name.inject({}) do |map, (name, id_list)|
      map[name] = Set.new(id_list)
      map
    end
  end

  let(:policies_list) do
    {
      "aar" => {
        "revisions" => {
          "37f9b658cdd1d9319bac8920581723efcc2014304b5f3827ee0779e10ffbdcc9" => {},
        },
      },
      "jenkins" => {
        "revisions" => {
          "613f803bdd035d574df7fa6da525b38df45a74ca82b38b79655efed8a189e073" => {},
          "6fe753184c8946052d3231bb4212116df28d89a3a5f7ae52832ad408419dd5eb" => {},
        },
      },
    }
  end

  let(:http_client) { instance_double(Chef::ServerAPI) }

  let(:ui) { TestHelpers::TestUI.new }

  let(:chef_config) do
    double("Chef::Config",
           chef_server_url: "https://localhost:10443",
           client_key: "/path/to/client/key.pem",
           node_name: "deuce")
  end

  subject(:clean_policy_cookbooks_service) do
    described_class.new(ui: ui, config: chef_config)
  end

  it "configures an HTTP client with the user's credentials" do
    expect(Chef::ServerAPI).to receive(:new).with("https://localhost:10443",
                                                       signing_key_filename: "/path/to/client/key.pem",
                                                       client_name: "deuce")
    clean_policy_cookbooks_service.http_client
  end

  context "when an error occurs fetching cookbook data from the server" do

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
      allow(clean_policy_cookbooks_service).to receive(:http_client).and_return(http_client)
      expect(http_client).to receive(:get).with("/policies").and_return({})
      expect(http_client).to receive(:get).with("/cookbook_artifacts").and_raise(http_exception)
    end

    it "raises a standardized nested exception" do
      expect { clean_policy_cookbooks_service.run }.to raise_error(ChefDK::PolicyCookbookCleanError)
    end

  end

  context "when the server returns cookbook data successfully" do

    before do
      allow(clean_policy_cookbooks_service).to receive(:http_client).and_return(http_client)

      allow(http_client).to receive(:get).with("/cookbook_artifacts").and_return(cookbook_artifacts_list)
      allow(http_client).to receive(:get).with("/policies").and_return(policies_list)
    end

    context "when the server has no policy cookbooks" do

      let(:cookbook_artifacts_list) { {} }
      let(:policies_list) { {} }

      it "has an empty list for all cookbooks" do
        expect(clean_policy_cookbooks_service.all_cookbooks).to eq({})
      end

      it "has no in-use cookbook artifacts" do
        expect(clean_policy_cookbooks_service.active_cookbooks).to eq({})
      end

      it "has no cookbooks to clean" do
        expect(clean_policy_cookbooks_service.cookbooks_to_clean).to eq({})
      end

      it "does not clean any cookbooks" do
        expect(http_client).to_not receive(:delete)
        clean_policy_cookbooks_service.run
      end
    end

    context "when the server has policy cookbooks" do

      let(:policy_aar_37f9b65) do
        {
          "cookbook_locks" => {
            "mysql" => { "identifier" => "6b506252cae939c874bd59b560c339b01c31326b" },
          },
        }
      end

      let(:policy_jenkins_613f803) do
        {
          "cookbook_locks" => {
            "mysql" => { "identifier" => "6b506252cae939c874bd59b560c339b01c31326b" },
            "build-essential" => { "identifier" => "2db3df121028894f45497f847de91b91fbf76824" },
          },
        }
      end

      let(:policy_jenkins_6fe7531) do
        {
          "cookbook_locks" => {
            "mysql" => { "identifier" => "6b506252cae939c874bd59b560c339b01c31326b" },
            "build-essential" => { "identifier" => "d8ce58401d154378599b0fead81d2c390615602b" },
          },
        }
      end

      before do
        allow(http_client).to receive(:get).
          with("/policies/aar/revisions/37f9b658cdd1d9319bac8920581723efcc2014304b5f3827ee0779e10ffbdcc9").
          and_return(policy_aar_37f9b65)
        allow(http_client).to receive(:get).
          with("/policies/jenkins/revisions/613f803bdd035d574df7fa6da525b38df45a74ca82b38b79655efed8a189e073").
          and_return(policy_jenkins_613f803)
        allow(http_client).to receive(:get).
          with("/policies/jenkins/revisions/6fe753184c8946052d3231bb4212116df28d89a3a5f7ae52832ad408419dd5eb").
          and_return(policy_jenkins_6fe7531)
      end

      context "and all cookbooks are active" do

        it "lists all the cookbooks" do
          expect(clean_policy_cookbooks_service.all_cookbooks).to eq(cookbook_ids_by_name)
        end

        it "lists all active cookbooks" do
          expect(clean_policy_cookbooks_service.active_cookbooks).to eq(cookbook_ids_in_sets_by_name)
        end

        it "has no cookbooks to clean" do
          expect(clean_policy_cookbooks_service.cookbooks_to_clean).to eq({})
        end

        it "does not clean any cookbooks" do
          expect(http_client).to_not receive(:delete)
          clean_policy_cookbooks_service.run
        end
      end

      context "and some cookbooks can be GC'd" do

        let(:policy_jenkins_6fe7531) do
          {
            "cookbook_locks" => {
              "mysql" => { "identifier" => "6b506252cae939c874bd59b560c339b01c31326b" },
              # this is changed to reference the same cookbook as policy_jenkins_613f803
              "build-essential" => { "identifier" => "2db3df121028894f45497f847de91b91fbf76824" },
            },
          }
        end

        let(:expected_active_cookbooks) do
          {
            "mysql" => Set.new([ "6b506252cae939c874bd59b560c339b01c31326b" ]),
            "build-essential" => Set.new([ "2db3df121028894f45497f847de91b91fbf76824" ]),
          }
        end

        it "lists all the cookbooks" do
          expect(clean_policy_cookbooks_service.all_cookbooks).to eq(cookbook_ids_by_name)
        end

        it "lists all active cookbooks" do
          expect(clean_policy_cookbooks_service.active_cookbooks).to eq(expected_active_cookbooks)
        end

        it "lists non-active cookbooks" do
          expected = { "build-essential" => Set.new([ "d8ce58401d154378599b0fead81d2c390615602b" ]) }
          expect(clean_policy_cookbooks_service.cookbooks_to_clean).to eq(expected)
        end

        it "deletes the non-active cookbooks" do
          expect(http_client).to receive(:delete).with("/cookbook_artifacts/build-essential/d8ce58401d154378599b0fead81d2c390615602b")
          clean_policy_cookbooks_service.run
        end

        # Regression test. This was giving us an Argument error for `<Set> - nil`
        context "when there are no active revisions of a given cookbook" do

          let(:policies_list) { {} }

          it "deletes the non-active cookbooks" do
            expect(http_client).to receive(:delete).with("/cookbook_artifacts/build-essential/d8ce58401d154378599b0fead81d2c390615602b")
            expect(http_client).to receive(:delete).with("/cookbook_artifacts/build-essential/2db3df121028894f45497f847de91b91fbf76824")
            expect(http_client).to receive(:delete).with("/cookbook_artifacts/mysql/6b506252cae939c874bd59b560c339b01c31326b")
            clean_policy_cookbooks_service.run
          end

        end

      end
    end
  end

end
