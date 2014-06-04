#
# Copyright:: Copyright (c) 2014 Chef Software Inc.
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

require 'spec_helper'
require 'chef-dk/policyfile_compiler'

describe ChefDK::PolicyfileCompiler, "when expressing the Policyfile graph demands" do

  let(:run_list) { [] }

  let(:default_source) { nil }

  let(:cache_manager) { double("Cookbook Cache Manager", universe_graph: external_cookbook_universe) }

  let(:external_cookbook_universe) { {} }

  let(:policyfile) do
    ChefDK::PolicyfileCompiler.new("", "TestPolicyfile.rb").tap do |p|
      p.default_source(*default_source) if default_source
      p.run_list(*run_list)
      p.stub(:cache_manager).and_return(cache_manager)
    end
  end

  let(:demands) { policyfile.graph_demands }

  shared_context("community default source") do

    let(:default_source) { [:community] }

    let(:external_cookbook_universe) do
      {
        "nginx" => {
          "1.0.0" => [ [ "apt", "~> 2.0" ], [ "yum", "~> 1.0" ] ],
          "1.2.0" => [ [ "apt", "~> 2.1" ], [ "yum", "~> 1.0" ] ],
          "2.0.0" => [ [ "apt", "~> 3.0" ], [ "yum", "~> 1.0" ], [ "ohai", "~> 2.0" ] ]
        },

        "mysql" => {
          "3.0.0" => [ [ "apt", "~> 2.0" ], [ "yum", "~> 1.0" ] ],
          "4.0.0" => [ [ "apt", "~> 2.4" ], [ "yum", "~> 1.1" ] ],
          "5.0.0" => [ ],
        },

        "local-cookbook" => {
          "9.9.9" => [ ["local-cookbook-on-community-dep", "= 1.0.0"] ]
        },

        "git-sourced-cookbook" => {
          "10.10.10" => [ ["git-sourced-cookbook-dep", "= 1.0.0"] ]
        },

        "remote-cb" => {
          "1.1.1" => [ ]
        }

      }
    end
  end

  shared_context("chef server default source") do

    let(:default_source) { [:chef_server, "https://chef.example.com"] }

    let(:external_cookbook_universe) do
      {
        "nginx" => {
          "1.0.0" => [ [ "apt", "~> 2.0" ], [ "yum", "~> 1.0" ] ],
        },

        "mysql" => {
          "5.0.0" => [ ],
        },

        "local-cookbook" => {
          "9.9.9" => [ ["local-cookbook-on-community-dep", "= 1.0.0"] ]
        },

        "remote-cb" => {
          "1.1.1" => [ ]
        },

        "git-sourced-cookbook" => {
          "10.10.10" => [ ["git-sourced-cookbook-dep", "= 1.0.0"] ]
        },

        "private-cookbook" => {
          "0.1.0" => [ ]
        }
      }
    end
  end


  before do
    expect(policyfile.errors).to eq([])
  end

  context "Given no local or git cookbooks, no default source, and an empty run list" do

    let(:run_list) { [] }

    it "has an empty set of demands" do
      expect(demands).to eq([])
    end

    it "uses an empty universe for dependencies" do
      expect(policyfile.artifacts_graph).to eq({})
    end
  end

  context "Given a run list and no local or git cookbooks" do

    let(:run_list) { ["remote-cb"] }

    context "And the default source is the community site" do

      include_context "community default source"

      it "has an unconstrained demand on the required cookbooks" do
        expect(demands).to eq([["remote-cb", ">= 0.0.0"]])
      end

      it "uses the community site universe for dependencies" do
        expect(policyfile.artifacts_graph).to eq(external_cookbook_universe)
      end
    end

    context "And the default source is the chef-server" do

      include_context "chef server default source"

      it "has an unconstrained demand on the required cookbooks" do
        expect(demands).to eq([["remote-cb", ">= 0.0.0"]])
      end

      it "uses the chef-server universe for dependencies" do
        expect(policyfile.artifacts_graph).to eq(external_cookbook_universe)
      end
    end
  end

  context "Given a local cookbook and only that cookbook in the run list" do

    let(:run_list) { ['local-cookbook'] }

    before do
      policyfile.cookbook('local-cookbook', path: "/foo")
      cache_manager.stub(:cookbook_version).with("local-cookbook").and_return("2.3.4")
      cache_manager.stub(:cookbook_dependencies).with("local-cookbook").and_return({ "2.3.4" => [] })
    end

    it "demands a solution using the local cookbook" do
      expect(demands).to eq([["local-cookbook", "= 2.3.4"]])
    end

    it "includes the local cookbook in the artifact universe" do
      expected_artifacts_graph = {
        "local-cookbook" => { "2.3.4" => [] }
      }
      expect(policyfile.artifacts_graph).to eq(expected_artifacts_graph)
    end

  end

  context "Given a local cookbook with a dependency and only the local cookbook in the run list" do

    let(:run_list) { ['local-cookbook'] }

    context "And the default source is the community site" do

      include_context "community default source"

      before do
        policyfile.cookbook("local-cookbook", path: "foo/")
        cache_manager.stub(:cookbook_version).with("local-cookbook").and_return("2.3.4")
        cache_manager.stub(:cookbook_dependencies).with("local-cookbook").and_return({
          "2.3.4" => [ [ "local-cookbook-dep-one", "~> 1.0"] ]
        })
      end

      it "demands a solution using the local cookbook" do
        expect(demands).to eq([["local-cookbook", "= 2.3.4"]])
      end

      it "overrides the community site universe with the local cookbook and its dependencies" do
        expected_artifacts_graph = external_cookbook_universe.dup
        expected_artifacts_graph["local-cookbook"] = {
          "2.3.4" =>  [ [ "local-cookbook-dep-one", "~> 1.0" ] ]
        }
        expect(policyfile.artifacts_graph).to eq(expected_artifacts_graph)
      end

    end
    context "And the default source is the chef server" do

      include_context "chef server default source"

      before do
        policyfile.cookbook("local-cookbook", path: "foo/")
        cache_manager.stub(:cookbook_version).with("local-cookbook").and_return("2.3.4")
        cache_manager.stub(:cookbook_dependencies).with("local-cookbook").and_return({
          "2.3.4" => [ [ "local-cookbook-dep-one", "~> 1.0"] ]
        })
      end

      it "demands a solution using the local cookbook" do
        expect(demands).to eq([["local-cookbook", "= 2.3.4"]])
      end

      it "overrides the chef server universe with the local cookbook and its dependencies" do
        # all versions of "local-cookbook" from the cookbook site universe
        # should be removed so we won't run into trouble if there's a community
        # cookbook with the same name and version but different deps.
        expected_artifacts_graph = external_cookbook_universe.dup
        expected_artifacts_graph["local-cookbook"] = {
          "2.3.4" => [ [ "local-cookbook-dep-one", "~> 1.0" ] ]
        }
        expect(policyfile.artifacts_graph).to eq(expected_artifacts_graph)
      end
    end
  end

  context "Given a git-sourced cookbook with no dependencies and only the git cookbook in the run list" do

    let(:run_list) { ["git-sourced-cookbook"] }

    before do
      policyfile.cookbook("git-sourced-cookbook", git: "git://git.example.org:user/a-cookbook.git")
      cache_manager.stub(:cookbook_version).with("git-sourced-cookbook").and_return("8.6.7")
      cache_manager.stub(:cookbook_dependencies).with("git-sourced-cookbook").and_return({
        "8.6.7" => [ ]
      })
    end

    it "demands a solution using the git sourced cookbook" do
      expect(demands).to eq([["git-sourced-cookbook", "= 8.6.7"]])
    end

    it "includes the git-sourced cookbook in the universe graph" do
      expected_artifacts_graph = {
        "git-sourced-cookbook" => { "8.6.7" => [ ] }
      }
      expect(policyfile.artifacts_graph).to eq(expected_artifacts_graph)
    end
  end

  context "Given a git-sourced cookbook with a dependency and only the git cookbook in the run list" do

    let(:run_list) { ["git-sourced-cookbook"] }

    before do
      policyfile.cookbook("git-sourced-cookbook", git: "git://git.example.org:user/a-cookbook.git")
      cache_manager.stub(:cookbook_version).with("git-sourced-cookbook").and_return("8.6.7")
      cache_manager.stub(:cookbook_dependencies).with("git-sourced-cookbook").and_return({
        "8.6.7" => [ ["git-sourced-cookbook-dep", "~> 2.2" ] ]
      })
    end

    context "And the default source is the community site" do

      include_context "community default source"

      it "demands a solution using the git sourced cookbook" do
        expect(demands).to eq([["git-sourced-cookbook", "= 8.6.7"]])
      end

      it "overrides the community site universe with the git-sourced cookbook and deps" do
        expected_artifacts_graph = external_cookbook_universe.dup
        expected_artifacts_graph["git-sourced-cookbook"] = {
          "8.6.7" => [ ["git-sourced-cookbook-dep", "~> 2.2" ] ]
        }
        expect(policyfile.artifacts_graph).to eq(expected_artifacts_graph)
      end

    end

    context "And the default source is the chef server" do

      include_context "chef server default source"

      it "demands a solution using the git sourced cookbook" do
        expect(demands).to eq([["git-sourced-cookbook", "= 8.6.7"]])
      end

      it "overrides the chef server universe with the git-sourced cookbook and deps" do
        expected_artifacts_graph = external_cookbook_universe.dup
        expected_artifacts_graph["git-sourced-cookbook"] = {
          "8.6.7" => [ ["git-sourced-cookbook-dep", "~> 2.2" ] ]
        }
        expect(policyfile.artifacts_graph).to eq(expected_artifacts_graph)
      end

    end
  end

  context "Given a local cookbook with a run list containing the local cookbook and another cookbook" do

    let(:run_list) { ['local-cookbook', 'remote-cookbook'] }

    before do
      policyfile.cookbook("local-cookbook", path: "foo/")
      cache_manager.stub(:cookbook_version).with("local-cookbook").and_return("2.3.4")
      cache_manager.stub(:cookbook_dependencies).with("local-cookbook").and_return("2.3.4" => [])
    end

    context "And the default source is the community site" do

      include_context "community default source"

      it "demands a solution with the local cookbook and any version of the other cookbook" do
        expect(demands).to eq([["local-cookbook", "= 2.3.4"], ["remote-cookbook", ">= 0.0.0"]])
      end

      it "overrides the community universe with the local cookbook and deps" do
        expected_artifacts_graph = external_cookbook_universe.dup
        expected_artifacts_graph["local-cookbook"] = { "2.3.4" => [ ] }
        expect(policyfile.artifacts_graph).to eq(expected_artifacts_graph)
      end

    end

    context "And the default source is the chef server" do

      include_context "chef server default source"

      it "demands a solution with the local cookbook and any version of the other cookbook" do
        expect(demands).to eq([["local-cookbook", "= 2.3.4"], ["remote-cookbook", ">= 0.0.0"]])
      end

      it "overrides the chef-server universe with the local cookbook and deps" do
        expected_artifacts_graph = external_cookbook_universe.dup
        expected_artifacts_graph["local-cookbook"] = { "2.3.4" => [ ] }
        expect(policyfile.artifacts_graph).to eq(expected_artifacts_graph)
      end

    end
  end

  ##
  # TODO: this needs to be in a different test
  ##

  # context "Given a local cookbook with a dependency and another local cookbook that satisfies the dependency" do
  #   it "emits a solution using the local cookbooks"
  # end

  # context "Given a local cookbook with a dependency and a git cookbook that satisfies the dependency" do
  #   it "emits a solution with the git and local cookbooks"
  # end

  # context "Given two local cookbooks with conflicting dependencies" do
  #   it "raises an error explaining that no solution was found."
  # end

  # context "Given a local cookbook with dependencies with conflicting transitive dependencies" do
  #   it "raises an error explaining that no solution was found."
  # end

  context "Given a run_list with roles" do
    it "expands the roles from the given role source" do
      pending
    end
  end

end
