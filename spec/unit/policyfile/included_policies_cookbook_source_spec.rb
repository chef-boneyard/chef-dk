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
require "chef-dk/policyfile/included_policies_cookbook_source"
require "chef-dk/policyfile/policyfile_location_specification"

describe ChefDK::Policyfile::IncludedPoliciesCookbookSource do

  let(:external_cookbook_universe) do
    {
      "cookbookA" => {
        "1.0.0" => [ ],
        "2.0.0" => [ ["cookbookB", "= 1.0.0" ] ],
      },
      "cookbookB" => {
        "1.0.0" => [ ],
      },
      "cookbookC" => {
        "1.0.0" => [ ],
        "2.0.0" => [ ],
      },
    }
  end

  let(:policy1_cookbooks) do
    [
      {
        name: "cookbookA",
        version: "2.0.0",
      },
      # cookbookB because cookbookA depends on it
      {
        name: "cookbookB",
        version: "1.0.0",
      },
    ]
  end

  let(:randomize_sources) { false }
  let(:add_random_cookbook) { false }

  def build_lockdata(cookbooks)
    nonce = if randomize_sources
              Random.rand
            else
              nil
            end

    cookbook_locks = cookbooks.inject({}) do |acc, cookbook_info|
      acc[cookbook_info[:name]] = {
        "version" => cookbook_info[:version],
        "identifier" => "identifier",
        "dotted_decimal_identifier" => "dotted_decimal_identifier",
        "cache_key" => "#{cookbook_info[:name]}-#{cookbook_info[:version]}",
        "origin" => "uri",
        "source_options" => { "version" => cookbook_info[:version] }.tap do |so|
          so["nonce"] = nonce if !nonce.nil?
        end,
      }
      acc
    end

    solution_dependencies_lock = cookbooks.map do |cookbook_info|
      [cookbook_info[:name], cookbook_info[:version]]
    end

    solution_dependencies_cookbooks = cookbooks.inject({}) do |acc, cookbook_info|
      acc["#{cookbook_info[:name]} (#{cookbook_info[:version]})"] = external_cookbook_universe[cookbook_info[:name]][cookbook_info[:version]]
      acc
    end

    {
      "name" => "included_policyfile",
      "revision_id" => "myrevisionid",
      "run_list" => ["recipe[myrunlist::default]"],
      "cookbook_locks" => cookbook_locks,
      "default_attributes" => {},
      "override_attributes" => {},
      "solution_dependencies" => {
        "Policyfile" => solution_dependencies_lock,
        ## We dont use dependencies, no need to fill it out
        "dependencies" => solution_dependencies_cookbooks,
      },
    }
  end

  let(:policy1_lockdata) do
    build_lockdata(policy1_cookbooks)
  end

  let(:policy2_lockdata) do
    build_lockdata(policy2_cookbooks)
  end

  let(:policy1_fetcher) do
    instance_double("ChefDK::Policyfile::LocalLockFetcher").tap do |double|
      allow(double).to receive(:lock_data).and_return(policy1_lockdata)
      allow(double).to receive(:valid?).and_return(true)
      allow(double).to receive(:errors).and_return([])
    end
  end

  let(:policy2_fetcher) do
    instance_double("ChefDK::Policyfile::LocalLockFetcher").tap do |double|
      allow(double).to receive(:lock_data).and_return(policy2_lockdata)
      allow(double).to receive(:valid?).and_return(true)
      allow(double).to receive(:errors).and_return([])
    end
  end

  let(:policy1_location_spec) do
    ChefDK::Policyfile::PolicyfileLocationSpecification.new("policy1", { path: "somelocation" }, nil).tap do |spec|
      allow(spec).to receive(:valid?).and_return(true)
      allow(spec).to receive(:fetcher).and_return(policy1_fetcher)
    end
  end

  let(:policy2_location_spec) do
    ChefDK::Policyfile::PolicyfileLocationSpecification.new("policy2", { path: "somelocation" }, nil).tap do |spec|
      allow(spec).to receive(:valid?).and_return(true)
      allow(spec).to receive(:fetcher).and_return(policy2_fetcher)
    end
  end

  let(:policyfiles) { [] }

  let(:cookbook_source) { ChefDK::Policyfile::IncludedPoliciesCookbookSource.new(policyfiles) }

  context "when no policies are included" do
    it "returns false for preferred_source_for" do
      expect(cookbook_source.preferred_source_for?("foo")).to eq(false)
    end

    it "has an empty universe" do
      expect(cookbook_source.universe_graph).to eq({})
    end
  end

  context "when a single policy is to be included" do
    let(:policyfiles) { [policy1_location_spec] }

    it "does not have a preferred source for unlocked cookbooks" do
      expect(cookbook_source.preferred_source_for?("cookbookC")).to eq(false)
    end

    it "has a preferred source for the included cookbooks" do
      expect(cookbook_source.preferred_source_for?("cookbookA")).to eq(true)
      expect(cookbook_source.preferred_source_for?("cookbookB")).to eq(true)
    end

    it "returns nil for the source options versions not included" do
      expect(cookbook_source.source_options_for("cookbookA", "1.0.0")).to eq(nil)
    end

    it "returns the correct source options when the cookbook is included" do
      expect(cookbook_source.source_options_for("cookbookA", "2.0.0")).to eq({ version: "2.0.0" })
      expect(cookbook_source.source_options_for("cookbookB", "1.0.0")).to eq({ version: "1.0.0" })
    end

    it "has a universe with the used cookbooks" do
      expect(cookbook_source.universe_graph).to eq({
        "cookbookA" => {
          "2.0.0" => external_cookbook_universe["cookbookA"]["2.0.0"],
        },
        "cookbookB" => {
          "1.0.0" => external_cookbook_universe["cookbookB"]["1.0.0"],
        },
      })
    end
  end

  context "when multiple policies are to be included" do
    let(:policyfiles) { [policy1_location_spec, policy2_location_spec] }

    context "when the policies use the same cookbooks with the same versions and sources" do
      let(:policy2_cookbooks) { policy1_cookbooks + [{ name: "cookbookC", version: "2.0.0" }] }

      it "has a preferred source for the included cookbooks" do
        expect(cookbook_source.preferred_source_for?("cookbookA")).to eq(true)
        expect(cookbook_source.preferred_source_for?("cookbookB")).to eq(true)
        expect(cookbook_source.preferred_source_for?("cookbookC")).to eq(true)
      end

      it "returns the correct source options when the cookbook is included" do
        expect(cookbook_source.source_options_for("cookbookA", "2.0.0")).to eq({ version: "2.0.0" })
        expect(cookbook_source.source_options_for("cookbookB", "1.0.0")).to eq({ version: "1.0.0" })
      end

      it "has a universe with the used cookbooks" do
        expect(cookbook_source.universe_graph).to eq({
          "cookbookA" => {
            "2.0.0" => external_cookbook_universe["cookbookA"]["2.0.0"],
          },
          "cookbookB" => {
            "1.0.0" => external_cookbook_universe["cookbookB"]["1.0.0"],
          },
          "cookbookC" => {
            "2.0.0" => external_cookbook_universe["cookbookC"]["2.0.0"],
          },
        })
      end
    end

    context "when the policies have the same versions with conflicting sources" do
      let(:randomize_sources) { true }
      let(:policy2_cookbooks) { policy1_cookbooks }

      it "raises an error when check_for_conflicts! is called" do
        expect { cookbook_source.check_for_conflicts! }.to raise_error(
          ChefDK::Policyfile::IncludedPoliciesCookbookSource::ConflictingCookbookSources)
      end
    end

    context "when the policies have conflicting versions" do
      let(:policy2_cookbooks) { [{ name: "cookbookA", version: "1.0.0" }] }

      it "raises an error when check_for_conflicts! is called" do
        expect { cookbook_source.check_for_conflicts! }.to raise_error(
          ChefDK::Policyfile::IncludedPoliciesCookbookSource::ConflictingCookbookVersions)
      end
    end

    context "when the policies have conflicting dependencies" do
      it "raises an error when check_for_conflicts! is called"
    end
  end
end
