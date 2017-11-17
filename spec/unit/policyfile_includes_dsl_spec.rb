#
# Copyright:: Copyright (c) 2017 Chef Software Inc.
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
require "chef-dk/policyfile_compiler"
require "chef-dk/exceptions"

describe ChefDK::PolicyfileCompiler, "including upstream policy locks" do

  let(:run_list) { ["local::default"] }
  let(:included_policies) { [] }

  let(:policyfile) do
    policyfile = ChefDK::PolicyfileCompiler.new.build do |p|

      p.run_list(*run_list)
      included_policies.each do |policy|
        p.include_policy(policy[0], policy[1])
      end
    end

    policyfile
  end

  describe "when include_policy specifies a policy on disk" do
    describe "and the included policy is correctly configured" do
      let(:included_policies) { [["foo", { path: "./foo.lock.json" }]] }

      it "has a included policy" do
        expect(policyfile.included_policies.length).to eq(1)
      end

      it "uses a local fetcher" do
        expect(policyfile.included_policies[0].fetcher).to be_a(ChefDK::Policyfile::LocalLockFetcher)
      end

      it "has a fetcher with no errors" do
        expect(policyfile.included_policies[0].fetcher.errors).to eq([])
      end

      it "has a fetcher that is valid" do
        expect(policyfile.included_policies[0].fetcher.valid?).to eq(true)
      end
    end

  end

  describe "when include_policy specifies a policy on a chef server" do
    let(:included_policies) { [["foo", { server: "http://example.com", policy_name: "foo" }]] }
    describe "and policy_revision_id and policy_group are missing" do
      it "has a dsl with errors" do
        expect(policyfile.dsl.errors.length).to eq(1)
        expect(policyfile.dsl.errors[0]).to match(/policy_revision_id/)
        expect(policyfile.dsl.errors[0]).to match(/policy_group/)
      end
    end

    describe "and the policy name is missing" do
      let(:included_policies) { [["foo", { server: "http://example.com", policy_revision_id: "bar" }]] }
      it "has no errors" do
        expect(policyfile.dsl.errors.length).to eq(0)
      end
    end

    describe "and everything is correctly configured" do
      context "using policy_revision_id" do
        let(:included_policies) { [["foo", { server: "http://example.com", policy_name: "foo", policy_revision_id: "bar" }]] }
        it "has a dsl with no errors" do
          expect(policyfile.dsl.errors.length).to eq(0)
        end

        it "has a included policy" do
          expect(policyfile.included_policies.length).to eq(1)
        end

        it "uses a server fetcher" do
          expect(policyfile.included_policies[0].fetcher).to be_a(ChefDK::Policyfile::ChefServerLockFetcher)
        end

        it "has a fetcher with no errors" do
          expect(policyfile.included_policies[0].fetcher.errors).to eq([])
        end

        it "has a fetcher that is valid" do
          expect(policyfile.included_policies[0].fetcher.valid?).to eq(true)
        end
      end
    end

    context "using policy_group" do
      let(:included_policies) { [["foo", { server: "http://example.com", policy_name: "foo", policy_group: "bar" }]] }
      it "has a dsl with no errors" do
        expect(policyfile.dsl.errors.length).to eq(0)
      end

      it "has a included policy" do
        expect(policyfile.included_policies.length).to eq(1)
      end

      it "uses a server fetcher" do
        expect(policyfile.included_policies[0].fetcher).to be_a(ChefDK::Policyfile::ChefServerLockFetcher)
      end

      it "has a fetcher with no errors" do
        expect(policyfile.included_policies[0].fetcher.errors).to eq([])
      end

      it "has a fetcher that is valid" do
        expect(policyfile.included_policies[0].fetcher.valid?).to eq(true)
      end
    end
  end

  describe "when include_policy specifies a policy fetched with an unknown method" do
    let(:included_policies) { [["foo", { foofetch: "bar" }]] }

    it "has a included policy" do
      expect(policyfile.included_policies.length).to eq(1)
    end

    it "has a dsl with an errors" do
      expect(policyfile.dsl.errors.length).to eq(1)
      expect(policyfile.dsl.errors[0]).to match(/include_policy must use one of the following/)
    end

    it "errors when trying to get the fetcher" do
      expect { policyfile.included_policies[0].fetcher }.to raise_error(ChefDK::InvalidPolicyfileLocation)
    end
  end

  describe "when a policy with the same name is specified multiple times" do
    let(:included_policies) do
      [
        ["foo", { path: "./foo.lock.json" }],
        ["foo", { path: "./foo.lock.json" }],
      ]
    end

    it "has a dsl with errors" do
      expect(policyfile.dsl.errors.length).to eq(1)
      expect(policyfile.dsl.errors[0]).to match(/assigned conflicting locations/)
    end
  end

end
