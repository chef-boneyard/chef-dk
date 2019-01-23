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
require "chef-dk/policyfile_services/clean_policies"

describe ChefDK::PolicyfileServices::CleanPolicies do

  let(:chef_config) { double("Chef::Config") }

  let(:policy_lister) do
    clean_policies_service.policy_lister
  end

  let(:policies_by_name) { {} }
  let(:policies_by_group) { {} }

  let(:ui) { TestHelpers::TestUI.new }

  subject(:clean_policies_service) do
    described_class.new(config: chef_config, ui: ui)
  end

  describe "when there is an error listing data from the server" do

    let(:http_client) { instance_double(Chef::ServerAPI) }

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
      expect(policy_lister).to receive(:http_client).and_return(http_client)
      expect(http_client).to receive(:get).and_raise(http_exception)
    end

    it "raises an error" do
      expect { clean_policies_service.run }.to raise_error(ChefDK::PolicyfileCleanError)
    end

  end

  context "when existing policies are listed successfully" do

    let(:http_client) { instance_double(Chef::ServerAPI) }

    before do
      policy_lister.set!(policies_by_name, policies_by_group)
    end

    describe "cleaning unused policy revisions" do

      before do
        allow(clean_policies_service).to receive(:http_client).and_return(http_client)
      end

      context "when there are no policies" do

        before do
          expect(http_client).to_not receive(:delete)
        end

        it "doesn't delete anything" do
          clean_policies_service.run
          expect(ui.output).to eq("No policy revisions deleted\n")
        end

      end

      context "when there are policies but none are orphans" do

        let(:policies_by_name) do
          {
            "appserver" => {
              "1111111111111111111111111111111111111111111111111111111111111111" => {},
              "2222222222222222222222222222222222222222222222222222222222222222" => {},
            },
            "load-balancer" => {
              "5555555555555555555555555555555555555555555555555555555555555555" => {},
              "6666666666666666666666666666666666666666666666666666666666666666" => {},
            },
          }
        end

        let(:policies_by_group) do
          {
            "dev" => {
              "appserver" => "1111111111111111111111111111111111111111111111111111111111111111",
              "load-balancer" => "5555555555555555555555555555555555555555555555555555555555555555",
            },
            "staging" => {
              "appserver" => "2222222222222222222222222222222222222222222222222222222222222222",
              "load-balancer" => "5555555555555555555555555555555555555555555555555555555555555555",
            },
            "prod" => {
              "appserver" => "2222222222222222222222222222222222222222222222222222222222222222",
              "load-balancer" => "6666666666666666666666666666666666666666666666666666666666666666",
            },
          }
        end

        before do
          expect(http_client).to_not receive(:delete)
        end

        it "doesn't delete anything" do
          clean_policies_service.run
          expect(ui.output).to eq("No policy revisions deleted\n")
        end

      end

      context "when there are policies and some are orphans" do

        let(:policies_by_name) do
          {
            "appserver" => {
              "1111111111111111111111111111111111111111111111111111111111111111" => {},
              "2222222222222222222222222222222222222222222222222222222222222222" => {},
              "4444444444444444444444444444444444444444444444444444444444444444" => {},
            },
            "load-balancer" => {
              "5555555555555555555555555555555555555555555555555555555555555555" => {},
              "6666666666666666666666666666666666666666666666666666666666666666" => {},
              "7777777777777777777777777777777777777777777777777777777777777777" => {},
            },
          }
        end

        let(:policies_by_group) do
          {
            "dev" => {
              "appserver" => "1111111111111111111111111111111111111111111111111111111111111111",
              "load-balancer" => "5555555555555555555555555555555555555555555555555555555555555555",
            },
            "staging" => {
              "appserver" => "2222222222222222222222222222222222222222222222222222222222222222",
              "load-balancer" => "5555555555555555555555555555555555555555555555555555555555555555",
            },
            "prod" => {
              "appserver" => "2222222222222222222222222222222222222222222222222222222222222222",
              "load-balancer" => "6666666666666666666666666666666666666666666666666666666666666666",
            },
          }
        end

        describe "and all deletes are successful" do

          before do
            expect(http_client).to receive(:delete).with("/policies/appserver/revisions/4444444444444444444444444444444444444444444444444444444444444444")
            expect(http_client).to receive(:delete).with("/policies/load-balancer/revisions/7777777777777777777777777777777777777777777777777777777777777777")
          end

          it "deletes the orphaned policies" do
            clean_policies_service.run
            expected_message = <<~MESSAGE
              DELETE appserver 4444444444444444444444444444444444444444444444444444444444444444
              DELETE load-balancer 7777777777777777777777777777777777777777777777777777777777777777
            MESSAGE
            expect(ui.output).to eq(expected_message)
          end

        end

        # For example, a user doesn't have permission on all policy_names
        describe "when some deletes fail" do

          let(:response) do
            Net::HTTPResponse.send(:response_class, "403").new("1.0", "403", "Unauthorized").tap do |r|
              r.instance_variable_set(:@body, "I can't let you do that Dave")
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
            expect(http_client).to receive(:delete)
              .with("/policies/appserver/revisions/4444444444444444444444444444444444444444444444444444444444444444")
              .and_raise(http_exception)
            expect(http_client).to receive(:delete).with("/policies/load-balancer/revisions/7777777777777777777777777777777777777777777777777777777777777777")
          end

          it "deletes what it can, then raises an error" do
            expected_message = <<~ERROR
              Failed to delete some policy revisions:
              - appserver (4444444444444444444444444444444444444444444444444444444444444444): Net::HTTPServerException 403 \"Unauthorized\"
            ERROR

            expect { clean_policies_service.run }.to raise_error do |error|
              expect(error.message).to eq(expected_message)
            end
            expected_message = <<~MESSAGE
              DELETE appserver 4444444444444444444444444444444444444444444444444444444444444444
              DELETE load-balancer 7777777777777777777777777777777777777777777777777777777777777777
            MESSAGE
            expect(ui.output).to eq(expected_message)
          end

        end

      end
    end

  end

end
