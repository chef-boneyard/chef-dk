# -*- coding: UTF-8 -*-
#
# Copyright:: Copyright (c) 2014-2018, Chef Software Inc.
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

  def expand_run_list(r)
    r.map do |item|
      "recipe[#{item}]"
    end
  end

  let(:run_list) { ["local::default"] }
  let(:run_list_expanded) { expand_run_list(run_list) }
  let(:named_run_list) { {} }
  let(:named_run_list_expanded) do
    named_run_list.inject({}) do |acc, (key, val)|
      acc[key] = expand_run_list(val)
      acc
    end
  end
  let(:default_attributes) { {} }
  let(:override_attributes) { {} }

  let(:default_source) { nil }

  let(:external_cookbook_universe) do
    {
      "cookbookA" => {
        "1.0.0" => [ ],
        "2.0.0" => [ ],
      },
      "cookbookB" => {
        "1.0.0" => [ ],
        "2.0.0" => [ ],
      },
      "cookbookC" => {
        "1.0.0" => [ ],
        "2.0.0" => [ ],
      },
      "local" => {
        "1.0.0" => [ ["cookbookC", "= 1.0.0" ] ],
      },
      "local_easy" => {
        "1.0.0" => [ ["cookbookC", "= 2.0.0" ] ],
      },
    }
  end

  let(:included_policy_default_attributes) { {} }
  let(:included_policy_override_attributes) { {} }
  let(:included_policy_expanded_named_runlist) { nil }
  let(:included_policy_expanded_runlist) { ["recipe[cookbookA::default]"] }
  let(:included_policy_cookbooks) do
    [
      {
        name: "cookbookA",
        version: "2.0.0",
      },
    ]
  end

  let(:included_policy_lock_data) do
    cookbook_locks = included_policy_cookbooks.inject({}) do |acc, cookbook_info|
      acc[cookbook_info[:name]] = {
        "version" => cookbook_info[:version],
        "identifier" => "identifier",
        "dotted_decimal_identifier" => "dotted_decimal_identifier",
        "cache_key" => "#{cookbook_info[:name]}-#{cookbook_info[:version]}",
        "origin" => "uri",
        "source_options" => {},
      }
      acc
    end

    solution_dependencies_lock = included_policy_cookbooks.map do |cookbook_info|
      [cookbook_info[:name], cookbook_info[:version]]
    end

    solution_dependencies_cookbooks = included_policy_cookbooks.inject({}) do |acc, cookbook_info|
      acc["#{cookbook_info[:name]} (#{cookbook_info[:version]})"] = external_cookbook_universe[cookbook_info[:name]][cookbook_info[:version]]
      acc
    end

    {
      "name" => "included_policyfile",
      "revision_id" => "myrevisionid",
      "run_list" => included_policy_expanded_runlist,
      "cookbook_locks" => cookbook_locks,
      "default_attributes" => included_policy_default_attributes,
      "override_attributes" => included_policy_override_attributes,
      "solution_dependencies" => {
        "Policyfile" => solution_dependencies_lock,
        "dependencies" => solution_dependencies_cookbooks,
      },
    }.tap do |core|
      core["named_run_lists"] = included_policy_expanded_named_runlist if included_policy_expanded_named_runlist
    end
  end

  let(:included_policy_lock_name) { "included" }
  let(:included_policy_fetcher) do
    instance_double("ChefDK::Policyfile::LocalLockFetcher").tap do |double|
      allow(double).to receive(:lock_data).and_return(included_policy_lock_data)
      allow(double).to receive(:valid?).and_return(true)
      allow(double).to receive(:errors).and_return([])
    end
  end

  let(:lock_source_options) { { path: "somelocation" } }
  let(:included_policy_lock_spec) do
    ChefDK::Policyfile::PolicyfileLocationSpecification.new(included_policy_lock_name, lock_source_options, nil).tap do |spec|
      allow(spec).to receive(:valid?).and_return(true)
      allow(spec).to receive(:fetcher).and_return(included_policy_fetcher)
      allow(spec).to receive(:source_options_for_lock).and_return(lock_source_options)
    end
  end

  let(:included_policies) { [] }

  let(:policyfile) do
    policyfile = ChefDK::PolicyfileCompiler.new.build do |p|
      if default_source
        p.default_source.replace([default_source])
      else
        allow(p.default_source.first).to receive(:universe_graph).and_return(external_cookbook_universe)
        allow(p.default_source.first).to receive(:null?).and_return(false)
      end
      p.run_list(*run_list)

      named_run_list.each do |name, run_list|
        p.named_run_list(name, *run_list)
      end

      default_attributes.each do |(name, value)|
        p.default[name] = value
      end

      override_attributes.each do |(name, value)|
        p.override[name] = value
      end

      allow(p).to receive(:included_policies).and_return(included_policies)
    end

    policyfile
  end

  let(:policyfile_lock) do
    policyfile.lock
  end

  context "when no policies are included" do

    it "does not emit included policies information in the lockfile" do
      expect(policyfile_lock.to_lock["included_policies"]).to eq(nil)
    end

  end

  context "when one policy is included" do

    let(:included_policies) { [included_policy_lock_spec] }

    # currently you must have a run list in a policyfile, but it should now
    # become possible to make a combo-policy just by combining other policies
    context "when the including policy does not have a run list" do
      let(:run_list) { [] }

      it "emits a lockfile with an identical run list as the included policy" do
        expect(policyfile_lock.to_lock["run_list"]).to eq(included_policy_expanded_runlist)
      end

    end

    context "when the including policy has a run list" do

      it "appends run list items from the including policy to the included policy's run list, removing duplicates" do
        expect(policyfile_lock.to_lock["run_list"]).to eq(included_policy_expanded_runlist + run_list_expanded)
      end

    end

    context "when the policies have named run lists" do

      let(:included_policy_expanded_named_runlist) do
        {
          "shared" => ["recipe[cookbookA::included]"],
        }
      end

      context "and no named run lists are shared between the including and included policy" do

        let(:named_run_list) do
          {
            "local" => ["local::foo"],
          }
        end

        it "preserves the named run lists as given in both policies" do
          expect(policyfile_lock.to_lock["named_run_lists"]).to include(included_policy_expanded_named_runlist, named_run_list_expanded)
        end

      end

      context "and some named run lists are shared between the including and included policy" do

        let(:named_run_list) do
          {
            "shared" => ["local::foo"],
          }
        end

        it "appends run lists items from the including policy's run lists to the included policy's run lists" do
          expect(policyfile_lock.to_lock["named_run_lists"]["shared"]).to eq(included_policy_expanded_named_runlist["shared"] + named_run_list_expanded["shared"])
        end

      end

    end

    context "when no cookbooks are shared as dependencies or transitive dependencies" do
      let(:included_policy_expanded_runlist) { ["recipe[cookbookC::default]"] }
      let(:run_list) { ["cookbookA::default"] }

      it "does not raise a have conflicting dependency requirements error" do
        expect { policyfile_lock.to_lock }.not_to raise_error
      end

      it "emits a lockfile where cookbooks pulled from the upstream are at identical versions" do
        expect(policyfile_lock.to_lock["solution_dependencies"]["dependencies"]).to(
          have_key("cookbookC (2.0.0)"))
      end
    end

    context "when some cookbooks are shared as dependencies or transitive dependencies" do
      let(:included_policy_expanded_runlist) { ["recipe[cookbookC::default]"] }
      let(:included_policy_cookbooks) do
        [
          {
            name: "cookbookC",
            version: "2.0.0",
          },
        ]
      end

      context "and the including policy does not specify any sources" do
        let(:run_list) { [] }
        it "it defaults to those provided in the included policy lock" do
          expect(policyfile_lock.to_lock["solution_dependencies"]["dependencies"]).to(
            have_key("cookbookC (2.0.0)"))
        end
      end

      context "and the including policy specifies a source that is equivalent to the included policy" do
        let(:run_list) { [] }
        let(:default_source) { instance_double("ChefDK::Policyfile::NullCookbookSource") }

        before do
          allow(default_source).to receive(:preferred_cookbooks).and_return(["cookbookC"])
          allow(default_source).to receive(:source_options_for).with("cookbookC", "2.0.0").and_return({})
          allow(default_source).to receive(:null?).and_return(false)
          allow(default_source).to receive(:universe_graph).and_return(external_cookbook_universe)
          allow(default_source).to receive(:desc).and_return("source double")
        end

        it "it defaults to those provided in the included policy lock" do
          expect { policyfile_lock.to_lock }.not_to raise_error
        end
      end

      context "and the including policy specifies a source that is not equivalent to the included policy" do
        let(:run_list) { [] }
        let(:default_source) { instance_double("ChefDK::Policyfile::NullCookbookSource") }

        before do
          allow(default_source).to receive(:preferred_cookbooks).and_return(["cookbookC"])
          allow(default_source).to receive(:source_options_for).with("cookbookC", "2.0.0").and_return({ "foo" => "bar" })
          allow(default_source).to receive(:null?).and_return(false)
          allow(default_source).to receive(:universe_graph).and_return(external_cookbook_universe)
          allow(default_source).to receive(:desc).and_return("source double")
        end

        it "it raises an error" do
          expect { policyfile_lock.to_lock }.to raise_error(ChefDK::IncludePolicyCookbookSourceConflict)
        end
      end

      context "and the including policy's dependencies can be solved with the included policy's locks" do
        let(:run_list) { ["local_easy::default"] }

        it "solves the dependencies added by the top-level policyfile and emits them in the lockfile" do
          expect(policyfile_lock.to_lock["solution_dependencies"]["dependencies"]).to(
            have_key("cookbookC (2.0.0)"))
        end

      end

      context "and the including policy's dependencies cannot be solved with the included policy's locks" do
        let(:run_list) { ["local::default"] }

        it "raises an error describing the conflict" do
          expect { policyfile_lock.to_lock }.to raise_error(Solve::Errors::NoSolutionError)
        end

        it "includes the source of the conflicting dependency constraint from the including policy" do
          expect { policyfile_lock.to_lock }.to raise_error(Solve::Errors::NoSolutionError) do |e|
            expect(e.to_s).to match(/`cookbookC \(= 2.0.0\)`/) # This one comes from the included policy
            expect(e.to_s).to match(/`cookbookC \(= 1.0.0\)` required by `local-1.0.0`/) # This one comes from the included policy
          end
        end
      end
    end

    context "when default attributes are specified" do
      let(:default_attributes) do
        {
          "shared" => {
            "foo" => "bar",
          },
        }
      end

      context "when the included policy does not have attributes that conflict with the including policy" do
        let(:included_policy_default_attributes) do
          {
            "not_shared" => {
              "foo" => "bar",
            },
          }
        end

        it "emits a lockfile with the attributes from both merged" do
          expect(policyfile_lock.to_lock["default_attributes"]).to include(included_policy_default_attributes, default_attributes)
        end

      end

      context "when the included policy has attributes that conflict with the including policy, but provide the same value" do
        let(:included_policy_default_attributes) { default_attributes }

        it "emits a lockfile with the attributes from both merged" do
          expect(policyfile_lock.to_lock["default_attributes"]).to eq(default_attributes)
        end

      end

      context "when the included policy has attributes that conflict with the including policy's attributes" do
        let(:included_policy_default_attributes) do
          {
            "shared" => {
              "foo" => "not_bar",
            },
          }
        end

        it "raises an error describing all attribute conflicts" do
          expect { policyfile_lock.to_lock }.to raise_error(
            ChefDK::Policyfile::AttributeMergeChecker::ConflictError,
            "Attribute '[shared][foo]' provided conflicting values by the following sources [\"user-specified\", \"included\"]")
        end
      end
    end

    context "when override attributes are specified" do
      let(:override_attributes) do
        {
          "shared" => {
            "foo" => "bar",
          },
        }
      end

      context "when the included policy does not have attributes that conflict with the including policy" do
        let(:included_policy_override_attributes) do
          {
            "not_shared" => {
              "foo" => "bar",
            },
          }
        end

        it "emits a lockfile with the attributes from both merged" do
          expect(policyfile_lock.to_lock["override_attributes"]).to include(included_policy_override_attributes, override_attributes)
        end

      end

      context "when the included policy has attributes that conflict with the including policy, but provide the same value" do
        let(:included_policy_override_attributes) { override_attributes }

        it "emits a lockfile with the attributes from both merged" do
          expect(policyfile_lock.to_lock["override_attributes"]).to eq(override_attributes)
        end

      end

      context "when the included policy has attributes that conflict with the including policy's attributes" do
        let(:included_policy_override_attributes) do
          {
            "shared" => {
              "foo" => "not_bar",
            },
          }
        end

        it "raises an error describing all attribute conflicts" do
          expect { policyfile_lock.to_lock }.to raise_error(
            ChefDK::Policyfile::AttributeMergeChecker::ConflictError,
            "Attribute '[shared][foo]' provided conflicting values by the following sources [\"user-specified\", \"included\"]")
        end
      end
    end
  end

  context "when several policies are included" do
    let(:included_policy_2_default_attributes) { {} }
    let(:included_policy_2_override_attributes) { {} }
    let(:included_policy_2_expanded_named_runlist) { nil }
    let(:included_policy_2_expanded_runlist) { ["recipe[cookbookA::default]"] }
    let(:included_policy_2_cookbooks) do
      [
        {
          name: "cookbookA",
          version: "2.0.0",
        },
      ]
    end

    let(:included_policy_2_lock_data) do
      cookbook_locks = included_policy_2_cookbooks.inject({}) do |acc, cookbook_info|
        acc[cookbook_info[:name]] = {
          "version" => cookbook_info[:version],
          "identifier" => "identifier",
          "dotted_decimal_identifier" => "dotted_decimal_identifier",
          "cache_key" => "#{cookbook_info[:name]}-#{cookbook_info[:version]}",
          "origin" => "uri",
          "source_options" => {},
        }
        acc
      end

      solution_dependencies_lock = included_policy_2_cookbooks.map do |cookbook_info|
        [cookbook_info[:name], cookbook_info[:version]]
      end

      solution_dependencies_cookbooks = included_policy_2_cookbooks.inject({}) do |acc, cookbook_info|
        acc["#{cookbook_info[:name]} (#{cookbook_info[:version]})"] = external_cookbook_universe[cookbook_info[:name]][cookbook_info[:version]]
        acc
      end

      {
        "name" => "included_policy_2file",
        "revision_id" => "myrevisionid",
        "run_list" => included_policy_2_expanded_runlist,
        "cookbook_locks" => cookbook_locks,
        "default_attributes" => included_policy_2_default_attributes,
        "override_attributes" => included_policy_2_override_attributes,
        "solution_dependencies" => {
          "Policyfile" => solution_dependencies_lock,
          "dependencies" => solution_dependencies_cookbooks,
        },
      }.tap do |core|
        core["named_run_lists"] = included_policy_2_expanded_named_runlist if included_policy_2_expanded_named_runlist
      end
    end

    let(:included_policy_2_lock_name) { "included2" }
    let(:included_policy_2_fetcher) do
      instance_double("ChefDK::Policyfile::LocalLockFetcher").tap do |double|
        allow(double).to receive(:lock_data).and_return(included_policy_2_lock_data)
        allow(double).to receive(:valid?).and_return(true)
        allow(double).to receive(:errors).and_return([])
      end
    end

    let(:included_policy_2_lock_spec) do
      ChefDK::Policyfile::PolicyfileLocationSpecification.new(included_policy_2_lock_name, lock_source_options, nil).tap do |spec|
        allow(spec).to receive(:valid?).and_return(true)
        allow(spec).to receive(:fetcher).and_return(included_policy_2_fetcher)
        allow(spec).to receive(:source_options_for_lock).and_return(lock_source_options)
      end
    end

    let(:included_policies) { [included_policy_lock_spec, included_policy_2_lock_spec] }

    let(:run_list) { ["local::default"] }

    context "when no cookbooks are shared as dependencies or transitive dependencies by included policies" do
      let(:included_policy_expanded_runlist) { ["recipe[cookbookA::default]"] }
      let(:included_policy_cookbooks) do
        [
          {
            name: "cookbookA",
            version: "2.0.0",
          },
        ]
      end

      let(:included_policy_2_expanded_runlist) { ["recipe[cookbookB::default]"] }
      let(:included_policy_2_cookbooks) do
        [
          {
            name: "cookbookB",
            version: "2.0.0",
          },
        ]
      end

      it "does not raise a have conflicting dependency requirements error" do
        expect { policyfile_lock.to_lock }.not_to raise_error
      end

      it "emits a lockfile with the correct dependencies" do
        expect(policyfile_lock.to_lock["solution_dependencies"]["dependencies"]).to eq({
          "cookbookA (2.0.0)" => [],
          "cookbookB (2.0.0)" => [],
          "cookbookC (1.0.0)" => [],
          "local (1.0.0)" => [["cookbookC", "= 1.0.0"]],
        })
      end
    end

    context "when some cookbooks appear as dependencies or transitive dependencies of some included policies" do
      let(:included_policy_expanded_runlist) { ["recipe[cookbookC::default]"] }
      let(:included_policy_2_expanded_runlist) { ["recipe[cookbookC::default]"] }

      context "and the locked versions of the cookbooks match" do
        let(:included_policy_cookbooks) do
          [
            {
              name: "cookbookC",
              version: "1.0.0",
            },
          ]
        end

        let(:included_policy_2_cookbooks) do
          [
            {
              name: "cookbookC",
              version: "1.0.0",
            },
          ]
        end

        it "solves the dependencies with the matching versions" do
          expect(policyfile_lock.to_lock["solution_dependencies"]["dependencies"]).to eq({
            "cookbookC (1.0.0)" => [],
            "local (1.0.0)" => [["cookbookC", "= 1.0.0"]],
          })
        end
      end

      context "and the locked versions of the cookbooks do not match" do
        let(:included_policy_cookbooks) do
          [
            {
              name: "cookbookC",
              version: "1.0.0",
            },
          ]
        end

        let(:included_policy_2_cookbooks) do
          [
            {
              name: "cookbookC",
              version: "2.0.0",
            },
          ]
        end

        it "raises an error describing the conflict" do
          expect { policyfile_lock }.to raise_error(
            ChefDK::Policyfile::IncludedPoliciesCookbookSource::ConflictingCookbookVersions,
            /Multiple versions provided for cookbook cookbookC/
          )
        end
      end
    end

    context "when default attributes are specified" do
      context "when the included policies do not have conflicting attributes" do
        let(:included_policy_default_attributes) do
          {
            "not_conflict" => {
              "foo" => "bar",
            },
          }
        end
        let(:included_policy_2_default_attributes) do
          {
            "not_conflict" => {
              "foo" => "bar",
            },
          }
        end
        let(:default_attributes) do
          {
            "not_conflict" => {
              "bar" => "baz",
            },
          }
        end

        it "emits a lockfile with the included policies' attributes merged" do
          expect(policyfile_lock.to_lock["default_attributes"]).to eq({
            "not_conflict" => {
              "foo" => "bar",
              "bar" => "baz",
            },
          })
        end
      end

      context "when the included policies have conflicting attributes" do
        let(:included_policy_default_attributes) do
          {
            "conflict" => {
              "foo" => "bar",
            },
          }
        end

        let(:included_policy_2_default_attributes) do
          {
            "conflict" => {
              "foo" => "baz",
            },
          }
        end

        it "raises an error describing the conflict" do
          expect { policyfile_lock }.to raise_error(
            ChefDK::Policyfile::AttributeMergeChecker::ConflictError,
            "Attribute '[conflict][foo]' provided conflicting values by the following sources [\"included\", \"included2\"]")
        end
      end
    end

    context "when override attributes are specified" do
      context "when the included policies do not have conflicting attributes" do
        let(:included_policy_override_attributes) do
          {
            "not_conflict" => {
              "foo" => "bar",
            },
          }
        end
        let(:included_policy_2_override_attributes) do
          {
            "not_conflict" => {
              "foo" => "bar",
            },
          }
        end
        let(:override_attributes) do
          {
            "not_conflict" => {
              "bar" => "baz",
            },
          }
        end

        it "emits a lockfile with the included policies' attributes merged" do
          expect(policyfile_lock.to_lock["override_attributes"]).to eq({
            "not_conflict" => {
              "foo" => "bar",
              "bar" => "baz",
            },
          })
        end
      end

      context "when the included policies have conflicting attributes" do
        let(:included_policy_override_attributes) do
          {
            "conflict" => {
              "foo" => "bar",
            },
          }
        end

        let(:included_policy_2_override_attributes) do
          {
            "conflict" => {
              "foo" => "baz",
            },
          }
        end

        it "raises an error describing the conflict" do
          expect { policyfile_lock }.to raise_error(
            ChefDK::Policyfile::AttributeMergeChecker::ConflictError,
            "Attribute '[conflict][foo]' provided conflicting values by the following sources [\"included\", \"included2\"]")
        end
      end
    end

  end
end
