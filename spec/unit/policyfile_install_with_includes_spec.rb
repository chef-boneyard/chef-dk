# -*- coding: UTF-8 -*-
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
require "chef-dk/policyfile_lock.rb"

describe ChefDK::PolicyfileLock, "installing cookbooks from included policies" do

  let(:run_list) { ["local::default"] }

  let(:default_source) { [:community] }

  let(:external_cookbook_universe) do
    {
      "cookbookA" => {
        "1.0.0" => [ ],
        "2.0.0" => [ ["cookbookB", "= 2.0.0" ]],
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

  let(:included_policy_cookbook_universe) { external_cookbook_universe }

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
      # We need to manually specify the dependencies of cookbookA
      {
        name: "cookbookB",
        version: "2.0.0",
      },
    ]
  end

  let(:included_policy_source_options) do
    {
      "cookbookA" => {
        "2.0.0" => { artifactserver: "https://supermarket.example/c/cookbookA/2.0.0/download", version: "2.0.0", somekey: "withavalue" },
      },
      "cookbookB" => {
        "2.0.0" => { artifactserver: "https://supermarket.example/c/cookbookB/2.0.0/download", version: "2.0.0", somekey: "withavalue" },
      },
    }
  end

  let(:included_policy_lock_data) do
    cookbook_locks = included_policy_cookbooks.inject({}) do |acc, cookbook_info|
      acc[cookbook_info[:name]] = {
        "version" => cookbook_info[:version],
        "identifier" => "identifier",
        "dotted_decimal_identifier" => "dotted_decimal_identifier",
        "cache_key" => "#{cookbook_info[:name]}-#{cookbook_info[:version]}",
        "origin" => "uri",
        "source_options" => included_policy_source_options[cookbook_info[:name]][cookbook_info[:version]],
      }
      acc
    end

    solution_dependencies_lock = included_policy_cookbooks.map do |cookbook_info|
      [cookbook_info[:name], cookbook_info[:version]]
    end

    solution_dependencies_cookbooks = included_policy_cookbooks.inject({}) do |acc, cookbook_info|
      acc["#{cookbook_info[:name]} (#{cookbook_info[:version]})"] = included_policy_cookbook_universe[cookbook_info[:name]][cookbook_info[:version]]
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

  let(:lock_source_options) { { :local => "somelocation" } }

  let(:included_policy_lock_name) { "included" }

  let(:included_policy_fetcher) do
    instance_double("ChefDK::Policyfile::LocalLockFetcher").tap do |double|
      allow(double).to receive(:lock_data).and_return(included_policy_lock_data)
      allow(double).to receive(:valid?).and_return(true)
      allow(double).to receive(:errors).and_return([])
    end
  end

  let(:default_source_obj) do
    instance_double("ChefDK::Policyfile::CommunityCookbookSource")
  end

  let(:policyfile) do
    policyfile = ChefDK::PolicyfileCompiler.new.build do |p|
      p.run_list(*run_list)
    end

    allow(policyfile.dsl).to receive(:default_source).and_return([default_source_obj])

    allow(default_source_obj).to receive(:universe_graph).
      and_return(external_cookbook_universe)

    allow(default_source_obj).to receive(:null?).and_return(false)
    allow(default_source_obj).to receive(:preferred_cookbooks).and_return([])

    allow(policyfile).to receive(:included_policies).and_return([included_policy_lock_spec])

    policyfile
  end

  before do

    allow(default_source_obj).to receive(:preferred_source_for?).and_return(false)

    allow(default_source_obj).to receive(:source_options_for) do |cookbook_name, version|
      { artifactserver: "https://supermarket.example/c/#{cookbook_name}/#{version}/download", version: version }
    end

    allow(ChefDK::Policyfile::CookbookLocationSpecification).to receive(:new) do |cookbook_name, version_constraint, source_opts, storage_config|
      double = instance_double("ChefDK::Policyfile::CookbookLocationSpecification",
                      name: cookbook_name,
                      version_constraint: Semverse::Constraint.new(version_constraint),
                      ensure_cached: nil,
                      to_s: "#{cookbook_name} #{version_constraint}")
      allow(double).to receive(:cookbook_has_recipe?).and_return(true)
      allow(double).to receive(:installed?).and_return(true)
      allow(double).to receive(:mirrors_canonical_upstream?).and_return(true)
      allow(double).to receive(:cache_key).and_return("#{cookbook_name}-#{version_constraint}-#{source_opts}")
      allow(double).to receive(:uri).and_return("uri://#{cookbook_name}-#{version_constraint}-#{source_opts}")
      allow(double).to receive(:source_options_for_lock).and_return(source_opts)
      double
    end
  end

  context "when a policy is included from local disk" do
    let(:included_policy_lock_spec) do
      ChefDK::Policyfile::PolicyfileLocationSpecification.new(included_policy_lock_name, lock_source_options, nil).tap do |spec|
        allow(spec).to receive(:valid?).and_return(true)
        allow(spec).to receive(:fetcher).and_return(included_policy_fetcher)
        allow(spec).to receive(:source_options_for_lock).and_return(lock_source_options)
      end
    end

    before do
      policyfile.install
    end

    it "maintains the correct source locations for cookbooks from the included policy" do
      expect(policyfile.lock.cookbook_locks["cookbookA"].source_options).to eq(included_policy_source_options["cookbookA"]["2.0.0"])
      expect(policyfile.lock.cookbook_locks["cookbookB"].source_options).to eq(included_policy_source_options["cookbookB"]["2.0.0"])
    end

    it "maintains the correct source locations for cookbooks from the current policy" do
      expect(policyfile.lock.cookbook_locks["local"].source_options).to eq(default_source_obj.source_options_for("local", "1.0.0"))
      expect(policyfile.lock.cookbook_locks["cookbookC"].source_options).to eq(default_source_obj.source_options_for("cookbookC", "1.0.0"))
    end

    ## This requires being able to do a to_lock
    it "maintains identifiers for remote cookbooks"

    # TODO: Sicne the PolicyfileLocationSpecification is a mock, this isn't really testing anything about a local lockfile
    it "emits the included policy in the lock file" do
      lock = policyfile.lock
      allow(lock).to receive(:cookbook_locks_for_lockfile).and_return({})
      expect(lock.to_lock["included_policy_locks"]).to eq(
        [
          {
            "name" => included_policy_lock_name,
            "revision_id" => "myrevisionid",
            "source_options" => lock_source_options,
          },
        ])
    end

    context "and the included policy sources cookbooks from local disk" do
      # For example, imagine a directory layout like:
      #
      #    policies/
      #      - policy_that_includes_shared_policy_a.rb
      #      - shared_policy_folder/
      #        - shared_policy_a.rb
      #        - shared_policy_a.lock.json
      #        - shared_policy_b.rb
      #        - shared_policy_b.lock.json
      #    cookbooks/
      #      - webserver_cookbook/
      #        <etc.>
      #
      # In `policies/shared_policy_folder/shared_policy_a.rb`, a cookbook may be
      # sourced from local path with code like:
      #
      #     cookbook "webserver_cookbook", path: "../../cookbooks/webserver_cookbook"
      #
      # In the lockfile
      # `policies/shared_policy_folder/shared_policy_a.lock.json`, we'd have some
      # data like:
      #
      #     "cookbook_locks": {
      #       "webserver_cookbook": {
      #         "version": "0.1.0",
      #         "identifier": "ea96c99da079db9ff3cb22601638fabd5df49599",
      #         "source": "../../cookbooks/webserver_cookbook",
      #
      # However, when we want to `chef install` cookbooks for
      # `policy_that_includes_shared_policy_a.rb`, we are one directory higher
      # and the path needs to be adjusted to `../cookbooks/webserver_cookbook` (only one set of `..`s)
      it "adjusts relative paths for local path cookbooks"

      # counter-example to above, if the filesystem path is absolute, leave it as-is
      it "does not adjust non-relative paths for local path cookbooks"

      context "and the local path cookbook content is unchanged" do

        it "does not raise an error when installing"

      end

      context "and the local path cookbook is modified so the identifier doesn't match" do

        it "raises an error when installing"

        it "suggests that the error may be resolved by updating the included policy"

      end

      context "and the local path cookbook does not exist" do

        it "raises an error when installing"

        it "includes the name and source location of the included policy"

      end

    end
  end

  context "when a policy is included from a Chef Server" do

    it "maintains source locations for remote cookbooks (i.e., from github or supermarket)"

    it "maintains identifiers for remote cookbooks"

    context "and the included policy sources cookbooks from local disk" do

      # NOTE: this will need to be a new kind of source in CookbookOmnifetch.
      # We have support for "regular" cookbooks in Chef Server, but for this
      # case we need to get the actual cookbook artifact at the specified revision_id
      it "adjusts the source location for the cookbook to the Chef Server's cookbook artifact store"

      it "maintains the identifier for the cookbooks"

      context "and the cookbook_artifact has been removed from the chef server" do

        # If the user is correctly using `chef clean-policy-revisions` and
        # `chef clean-policy-cookbooks`, this case shouldn't occur, but should
        # still have a clean and informative error
        it "raises an error explaining that the included policy depends on a cookbook artifact that has been deleted"

      end

    end
  end

  context "when a policy is included from a remote git repo" do

    context "and the included policy sources cookbooks from local disk" do

      # ¯\_(ツ)_/¯
      it "raises an error explaining that local path cookbooks cannot be used in policies included from git repos"

    end
  end
end
