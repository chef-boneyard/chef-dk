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

  let(:external_cookbook_universe) { {} }

  let(:policyfile) do
    policyfile = ChefDK::PolicyfileCompiler.new.build do |p|

      p.default_source(*default_source) if default_source
      p.run_list(*run_list)

      allow(p.default_source.first).to receive(:universe_graph).and_return(external_cookbook_universe)
    end

    policyfile
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
          "0.1.0" => [ ],
          "1.1.1" => [ ]
        },

        "remote-cb-two" => {
          "0.1.0" => [ ],
          "1.1.1" => [ ]
        },

        "local-cookbook-dep-one" => {
          "1.5.0" => [ ]
        },

        "git-sourced-cookbook-dep" => {
          "2.8.0" => [ ]
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
        },

        "local-cookbook-dep-one" => {
          "1.6.0" => [ ]
        },

        "git-sourced-cookbook-dep" => {
          "2.9.0" => [ ]
        }


      }
    end
  end

  describe "when normalizing run_list items" do

    it "normalizes a bare cookbook name" do
      policyfile.run_list("local-cookbook")
      expect(policyfile.normalized_run_list).to eq(["recipe[local-cookbook::default]"])
    end

    it "normalizes a bare cookbook::recipe item" do
      policyfile.run_list("local-cookbook::server")
      expect(policyfile.normalized_run_list).to eq(["recipe[local-cookbook::server]"])
    end

    it "normalizes a recipe[] item with implicit default" do
      policyfile.run_list("recipe[local-cookbook]")
      expect(policyfile.normalized_run_list).to eq(["recipe[local-cookbook::default]"])
    end

    it "does not modify a fully qualified recipe" do
      policyfile.run_list("recipe[local-cookbook::jazz_hands]")
      expect(policyfile.normalized_run_list).to eq(["recipe[local-cookbook::jazz_hands]"])
    end

    describe "in an alternate run list" do

      it "normalizes a bare cookbook name" do
        policyfile.named_run_list(:foo, "local-cookbook")
        expect(policyfile.normalized_named_run_lists[:foo]).to eq(["recipe[local-cookbook::default]"])
      end

      it "normalizes a bare cookbook::recipe item" do
        policyfile.named_run_list(:foo, "local-cookbook::server")
        expect(policyfile.normalized_named_run_lists[:foo]).to eq(["recipe[local-cookbook::server]"])
      end

      it "normalizes a recipe[] item with implicit default" do
        policyfile.named_run_list(:foo, "recipe[local-cookbook]")
        expect(policyfile.normalized_named_run_lists[:foo]).to eq(["recipe[local-cookbook::default]"])
      end

      it "does not modify a fully qualified recipe" do
        policyfile.named_run_list(:foo, "recipe[local-cookbook::jazz_hands]")
        expect(policyfile.normalized_named_run_lists[:foo]).to eq(["recipe[local-cookbook::jazz_hands]"])
      end

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

    it "has an empty solution" do
      expect(policyfile).to receive(:ensure_cache_dir_exists)
      expect(policyfile.graph_solution).to eq({})
    end

    it "has an empty set of solution_dependencies" do
      expected_solution_deps = {
        "Policyfile" => [],
        "dependencies" => {}
      }
      expect(policyfile.solution_dependencies.to_lock).to eq(expected_solution_deps)
    end
  end

  context "Given a run list and no local or git cookbooks" do

    let(:run_list) { ["remote-cb"] }

    context "with no default source" do

      it "fails to locate the cookbook" do
        expect { policyfile.graph_solution }.to raise_error(Solve::Errors::NoSolutionError)
      end

      context "when the policyfile also has a `cookbook` entry for the run list item" do

        before do
          policyfile.dsl.cookbook "remote-cb"
        end

        it "fails to locate the cookbook" do
          expect { policyfile.graph_solution }.to raise_error(Solve::Errors::NoSolutionError)
        end

      end

    end

    context "And the default source is the community site" do

      include_context "community default source"

      it "has an unconstrained demand on the required cookbooks" do
        expect(demands).to eq([["remote-cb", ">= 0.0.0"]])
      end

      it "uses the community site universe for dependencies" do
        expect(policyfile.artifacts_graph).to eq(external_cookbook_universe)
      end

      it "uses the community cookbook in the solution" do
        expect(policyfile).to receive(:ensure_cache_dir_exists)
        expect(policyfile.graph_solution).to eq({"remote-cb" => "1.1.1"})
      end

      it "includes the cookbook in the solution dependencies" do
        expected_solution_deps = {
          "Policyfile" => [],
          "dependencies" => { "remote-cb (1.1.1)" => [] }
        }
        expect(policyfile.solution_dependencies.to_lock).to eq(expected_solution_deps)
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

      it "uses the chef-server cookbook in the solution" do
        expect(policyfile).to receive(:ensure_cache_dir_exists)
        expect(policyfile.graph_solution).to eq({"remote-cb" => "1.1.1"})
      end
    end
  end

  context "Given a local cookbook and only that cookbook in the run list" do

    let(:run_list) { ['local-cookbook'] }

    before do
      policyfile.dsl.cookbook('local-cookbook', path: "/foo")
      allow(policyfile.cookbook_location_spec_for("local-cookbook")).to receive(:version).and_return("2.3.4")
      allow(policyfile.cookbook_location_spec_for("local-cookbook")).to receive(:dependencies).and_return([])
      allow(policyfile.cookbook_location_spec_for("local-cookbook")).to receive(:ensure_cached).and_return(true)
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

    it "includes the cookbook in the solution dependencies" do
      expected_solution_deps = {
        "Policyfile" => [ [ "local-cookbook", ">= 0.0.0" ] ],
        "dependencies" => { "local-cookbook (2.3.4)" => [] }
      }
      expect(policyfile.solution_dependencies.to_lock).to eq(expected_solution_deps)
    end

  end

  context "Given a local cookbook with a dependency and only the local cookbook in the run list" do

    let(:run_list) { ['local-cookbook'] }

    context "And the default source is the community site" do

      include_context "community default source"

      before do
        policyfile.dsl.cookbook("local-cookbook", path: "foo/")
        allow(policyfile.cookbook_location_spec_for("local-cookbook")).to receive(:ensure_cached)
        allow(policyfile.cookbook_location_spec_for("local-cookbook")).to receive(:version).and_return("2.3.4")
        allow(policyfile.cookbook_location_spec_for("local-cookbook")).to receive(:dependencies).and_return([ [ "local-cookbook-dep-one", "~> 1.0"] ])
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

      it "uses the local cookbook in the solution and gets dependencies remotely" do
        expect(policyfile).to receive(:ensure_cache_dir_exists)
        expect(policyfile.graph_solution).to eq({"local-cookbook" => "2.3.4", "local-cookbook-dep-one" => "1.5.0"})
      end

      it "includes the cookbook and dependencies in the solution dependencies" do
        expected_solution_deps = {
          "Policyfile" => [ [ "local-cookbook", ">= 0.0.0" ] ],
          "dependencies" => {
            "local-cookbook (2.3.4)" => [[ "local-cookbook-dep-one", "~> 1.0"]],
            "local-cookbook-dep-one (1.5.0)" => []
          }

        }
        expect(policyfile.solution_dependencies.to_lock).to eq(expected_solution_deps)
      end

    end
    context "And the default source is the chef server" do

      include_context "chef server default source"

      before do
        policyfile.dsl.cookbook("local-cookbook", path: "foo/")
        allow(policyfile.cookbook_location_spec_for("local-cookbook")).to receive(:ensure_cached)
        allow(policyfile.cookbook_location_spec_for("local-cookbook")).to receive(:version).and_return("2.3.4")
        allow(policyfile.cookbook_location_spec_for("local-cookbook")).to receive(:dependencies).and_return([ [ "local-cookbook-dep-one", "~> 1.0"] ])
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

      it "uses the local cookbook in the solution and gets dependencies remotely" do
        expect(policyfile).to receive(:ensure_cache_dir_exists)
        expect(policyfile.graph_solution).to eq({"local-cookbook" => "2.3.4", "local-cookbook-dep-one" => "1.6.0"})
      end

      it "includes the cookbook and dependencies in the solution dependencies" do
        expected_solution_deps = {
          "Policyfile" => [ [ "local-cookbook", ">= 0.0.0" ] ],
          "dependencies" => {
            "local-cookbook (2.3.4)" => [[ "local-cookbook-dep-one", "~> 1.0"]],
            "local-cookbook-dep-one (1.6.0)" => []
          }

        }
        expect(policyfile.solution_dependencies.to_lock).to eq(expected_solution_deps)
      end

    end
  end

  context "Given a git-sourced cookbook with no dependencies and only the git cookbook in the run list" do

    let(:run_list) { ["git-sourced-cookbook"] }

    before do
      policyfile.dsl.cookbook("git-sourced-cookbook", git: "git://git.example.org:user/a-cookbook.git")
      allow(policyfile.cookbook_location_spec_for("git-sourced-cookbook")).to receive(:ensure_cached)
      allow(policyfile.cookbook_location_spec_for("git-sourced-cookbook")).to receive(:version).and_return("8.6.7")
      allow(policyfile.cookbook_location_spec_for("git-sourced-cookbook")).to receive(:dependencies).and_return([ ])
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

    it "uses the git sourced cookbook in the solution" do
      expect(policyfile).to receive(:ensure_cache_dir_exists)
      expect(policyfile.graph_solution).to eq({"git-sourced-cookbook" => "8.6.7"})
    end

    it "includes the cookbook and dependencies in the solution dependencies" do
      expected_solution_deps = {
        "Policyfile" => [ [ "git-sourced-cookbook", ">= 0.0.0" ] ],
        "dependencies" => {
          "git-sourced-cookbook (8.6.7)" => []
        }

      }
      expect(policyfile.solution_dependencies.to_lock).to eq(expected_solution_deps)
    end

  end

  context "Given a git-sourced cookbook with a dependency and only the git cookbook in the run list" do

    let(:run_list) { ["git-sourced-cookbook"] }

    before do
      policyfile.dsl.cookbook("git-sourced-cookbook", git: "git://git.example.org:user/a-cookbook.git")
      allow(policyfile.cookbook_location_spec_for("git-sourced-cookbook")).to receive(:ensure_cached)
      allow(policyfile.cookbook_location_spec_for("git-sourced-cookbook")).to receive(:version).and_return("8.6.7")
      allow(policyfile.cookbook_location_spec_for("git-sourced-cookbook")).to receive(:dependencies).and_return([ ["git-sourced-cookbook-dep", "~> 2.2" ] ])
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

      it "uses the git sourced cookbook with remote dependencies in the solution" do
        expect(policyfile).to receive(:ensure_cache_dir_exists)
        expect(policyfile.graph_solution).to eq({"git-sourced-cookbook" => "8.6.7", "git-sourced-cookbook-dep" => "2.8.0"})
      end

      it "includes the cookbook and dependencies in the solution dependencies" do
        expected_solution_deps = {
          "Policyfile" => [ [ "git-sourced-cookbook", ">= 0.0.0" ] ],
          "dependencies" => {
            "git-sourced-cookbook (8.6.7)" => [ [ "git-sourced-cookbook-dep", "~> 2.2" ] ],
            "git-sourced-cookbook-dep (2.8.0)" => []
          }

        }
        expect(policyfile.solution_dependencies.to_lock).to eq(expected_solution_deps)
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

      it "uses the git sourced cookbook with remote dependencies in the solution" do
        expect(policyfile).to receive(:ensure_cache_dir_exists)
        expect(policyfile.graph_solution).to eq({"git-sourced-cookbook" => "8.6.7", "git-sourced-cookbook-dep" => "2.9.0"})
      end

      it "includes the cookbook and dependencies in the solution dependencies" do
        expected_solution_deps = {
          "Policyfile" => [ [ "git-sourced-cookbook", ">= 0.0.0" ] ],
          "dependencies" => {
            "git-sourced-cookbook (8.6.7)" => [ [ "git-sourced-cookbook-dep", "~> 2.2" ] ],
            "git-sourced-cookbook-dep (2.9.0)" => []
          }

        }
        expect(policyfile.solution_dependencies.to_lock).to eq(expected_solution_deps)
      end

    end
  end

  context "Given a local cookbook with a run list containing the local cookbook and another cookbook" do

    let(:run_list) { ['local-cookbook', 'remote-cb'] }

    before do
      policyfile.dsl.cookbook("local-cookbook", path: "foo/")
      allow(policyfile.cookbook_location_spec_for("local-cookbook")).to receive(:ensure_cached)
      allow(policyfile.cookbook_location_spec_for("local-cookbook")).to receive(:version).and_return("2.3.4")
      allow(policyfile.cookbook_location_spec_for("local-cookbook")).to receive(:dependencies).and_return([])
    end

    context "And the default source is the community site" do

      include_context "community default source"

      it "demands a solution with the local cookbook and any version of the other cookbook" do
        expect(demands).to eq([["local-cookbook", "= 2.3.4"], ["remote-cb", ">= 0.0.0"]])
      end

      it "overrides the community universe with the local cookbook and deps" do
        expected_artifacts_graph = external_cookbook_universe.dup
        expected_artifacts_graph["local-cookbook"] = { "2.3.4" => [ ] }
        expect(policyfile.artifacts_graph).to eq(expected_artifacts_graph)
      end

      it "uses the locally specified cookbook and remote cookbooks in the solution" do
        expect(policyfile).to receive(:ensure_cache_dir_exists)
        expect(policyfile.graph_solution).to eq({"local-cookbook" => "2.3.4", "remote-cb" => "1.1.1"})
      end

      it "includes the cookbook and dependencies in the solution dependencies" do
        expected_solution_deps = {
          "Policyfile" => [ [ "local-cookbook", ">= 0.0.0" ] ],
          "dependencies" => {
            "local-cookbook (2.3.4)" => [],
            "remote-cb (1.1.1)" => []
          }

        }
        expect(policyfile.solution_dependencies.to_lock).to eq(expected_solution_deps)
      end

    end

    context "And the default source is the chef server" do

      include_context "chef server default source"

      it "demands a solution with the local cookbook and any version of the other cookbook" do
        expect(demands).to eq([["local-cookbook", "= 2.3.4"], ["remote-cb", ">= 0.0.0"]])
      end

      it "overrides the chef-server universe with the local cookbook and deps" do
        expected_artifacts_graph = external_cookbook_universe.dup
        expected_artifacts_graph["local-cookbook"] = { "2.3.4" => [ ] }
        expect(policyfile.artifacts_graph).to eq(expected_artifacts_graph)
      end

      it "uses the locally specified cookbook and remote cookbooks in the solution" do
        expect(policyfile).to receive(:ensure_cache_dir_exists)
        expect(policyfile.graph_solution).to eq({"local-cookbook" => "2.3.4", "remote-cb" => "1.1.1"})
      end

      it "includes the cookbook and dependencies in the solution dependencies" do
        expected_solution_deps = {
          "Policyfile" => [ [ "local-cookbook", ">= 0.0.0" ] ],
          "dependencies" => {
            "local-cookbook (2.3.4)" => [],
            "remote-cb (1.1.1)" => []
          }

        }
        expect(policyfile.solution_dependencies.to_lock).to eq(expected_solution_deps)
      end

    end
  end

  context "given a cookbook with a version constraint in the policyfile" do

    include_context "community default source"

    let(:run_list) { ['remote-cb'] }

    before do
      policyfile.dsl.cookbook("remote-cb", "~> 0.1")
    end

    it "demands a solution that matches the version constraint in the policyfile" do
      expect(demands).to eq([["remote-cb", "~> 0.1"]])
    end

    it "emits a solution that satisfies the policyfile constraint" do
      expect(policyfile).to receive(:ensure_cache_dir_exists)
      expect(policyfile.graph_solution).to eq({"remote-cb" => "0.1.0"})
    end

    it "includes the policyfile constraint in the solution dependencies" do
      expected_solution_deps = {
        "Policyfile" => [ [ "remote-cb", "~> 0.1" ] ],
        "dependencies" => {
          "remote-cb (0.1.0)" => []
        }

      }
      expect(policyfile.solution_dependencies.to_lock).to eq(expected_solution_deps)
    end
  end

  context "given a cookbook that isn't in the run list is specified with a version constraint in the policyfile" do

    include_context "community default source"

    let(:run_list) { ['local-cookbook'] }

    before do
      policyfile.dsl.cookbook("remote-cb", "~> 0.1")

      policyfile.dsl.cookbook("local-cookbook", path: "foo/")

      allow(policyfile.cookbook_location_spec_for("local-cookbook")).to receive(:ensure_cached)
      allow(policyfile.cookbook_location_spec_for("local-cookbook")).to receive(:version).and_return("2.3.4")
      allow(policyfile.cookbook_location_spec_for("local-cookbook")).to receive(:dependencies).and_return([])
    end

    it "demands a solution that matches the version constraint in the policyfile" do
      expect(demands).to eq([["local-cookbook", "= 2.3.4"], ["remote-cb", "~> 0.1"]])
    end

    it "emits a solution that satisfies the policyfile constraint" do
      expect(policyfile).to receive(:ensure_cache_dir_exists)
      expect(policyfile.graph_solution).to eq({"local-cookbook" => "2.3.4", "remote-cb" => "0.1.0"})
    end

    it "includes the policyfile constraint in the solution dependencies" do
      expected_solution_deps = {
        "Policyfile" => [ [ "remote-cb", "~> 0.1" ], [ "local-cookbook", ">= 0.0.0"] ],
        "dependencies" => {
          "local-cookbook (2.3.4)" => [],
          "remote-cb (0.1.0)" => []
        }

      }
      expect(policyfile.solution_dependencies.to_lock).to eq(expected_solution_deps)
    end
  end

  context "Given a run_list and named run_lists" do

    before do
      policyfile.dsl.named_run_list(:foo, 'local-cookbook', 'nginx')
      policyfile.dsl.named_run_list(:bar, 'remote-cb', 'nginx')
      policyfile.dsl.run_list('private-cookbook', 'nginx')
    end

    it "demands a solution that satisfies all of the run lists, with no duplicates" do
      expect(policyfile.graph_demands).to include(["private-cookbook", ">= 0.0.0"])
      expect(policyfile.graph_demands).to include(["nginx", ">= 0.0.0"])
      expect(policyfile.graph_demands).to include(["remote-cb", ">= 0.0.0"])
      expect(policyfile.graph_demands).to include(["local-cookbook", ">= 0.0.0"])

      # ensure there are no duplicates:
      expected_demands = [["private-cookbook", ">= 0.0.0"],
                          ["nginx", ">= 0.0.0"],
                          ["local-cookbook", ">= 0.0.0"],
                          ["remote-cb", ">= 0.0.0"]]
      expect(policyfile.graph_demands).to eq(expected_demands)
    end

  end

  context "when using multiple default sources" do

    include_context "community default source"

    let(:run_list) { [ 'repo-cookbook-one', 'remote-cb', 'remote-cb-two' ] }

    before do
      policyfile.default_source(:chef_repo, "path/to/repo")
      allow(policyfile.default_source.last).to receive(:universe_graph).and_return(repo_cookbook_universe)
    end

    context "when the graphs don't conflict" do

      before do
        # This is on the community site
        policyfile.dsl.cookbook("remote-cb")
      end

      let(:repo_cookbook_universe) do
        {
          "repo-cookbook-one" => {
            "1.0.0" => [ ]
          },

          "repo-cookbook-two" => {
            "9.9.9" => [ ["repo-cookbook-on-community-dep", "= 1.0.0"] ]
          },

          "private-cookbook" => {
            "0.1.0" => [ ]
          }
        }
      end

      it "merges the graphs" do
        merged = policyfile.remote_artifacts_graph
        expected = external_cookbook_universe.merge(repo_cookbook_universe)

        expect(merged).to eq(expected)
      end

      it "solves the graph demands using cookbooks from both sources" do
        expected = {"repo-cookbook-one" => "1.0.0", "remote-cb" => "1.1.1", "remote-cb-two" => "1.1.1"}
        expect(policyfile.graph_solution).to eq(expected)
      end

      it "finds the location of a cookbook declared via explicit `cookbook` with no source options" do
        community_source = policyfile.default_source.first

        expected_source_options = { artifactserver: "https://chef.example/url", version: "1.1.1" }

        expect(community_source).to be_a(ChefDK::Policyfile::CommunityCookbookSource)
        expect(community_source).to receive(:source_options_for).
          with("remote-cb", "1.1.1").
          and_return(expected_source_options)

        location_spec = policyfile.create_spec_for_cookbook("remote-cb", "1.1.1")
        expect(location_spec.source_options).to eq(expected_source_options)
      end

      it "sources cookbooks from the correct source when the cookbook doesn't have a `cookbook` entry" do
        # these don't have `cookbook` entries in the Policyfile.rb, so they are nil
        expect(policyfile.cookbook_location_spec_for("repo-cookbook-one")).to be_nil
        expect(policyfile.cookbook_location_spec_for("remote-cb-two")).to be_nil

        # We have to stub #source_options_for or else we'd need to stub the
        # source options data inside the source object. That's getting a bit
        # too deep into the source object's internals.

        expected_repo_options = { path: "path/to/cookbook", version: "1.0.0" }
        repo_source = policyfile.default_source.last
        expect(repo_source).to be_a(ChefDK::Policyfile::ChefRepoCookbookSource)
        expect(repo_source).to receive(:source_options_for).
          with("repo-cookbook-one", "1.0.0").
          and_return(expected_repo_options)


        repo_cb_location = policyfile.create_spec_for_cookbook("repo-cookbook-one", "1.0.0")
        expect(repo_cb_location.source_options).to eq(expected_repo_options)

        expected_server_options = { artifactserver: "https://chef.example/url", version: "1.1.1" }
        community_source = policyfile.default_source.first
        expect(community_source).to be_a(ChefDK::Policyfile::CommunityCookbookSource)
        expect(community_source).to receive(:source_options_for).
          with("remote-cb-two", "1.1.1").
          and_return(expected_server_options)

        remote_cb_location = policyfile.create_spec_for_cookbook("remote-cb-two", "1.1.1")
        expect(remote_cb_location.source_options).to eq(expected_server_options)
      end

    end

    context "when the graphs conflict" do

      let(:repo_cookbook_universe) do
        {
          "repo-cookbook-one" => {
            "1.0.0" => [ ]
          },

          "repo-cookbook-two" => {
            "9.9.9" => [ ["repo-cookbook-on-community-dep", "= 1.0.0"] ]
          },

          "private-cookbook" => {
            "0.1.0" => [ ]
          },

          # NOTE: cookbooks are considered to conflict when both sources have
          # cookbooks with the same name, regardless of whether any version
          # numbers overlap.
          #
          # The before block does the equivalent to putting this in the
          # Policyfile.rb:
          #
          #   cookbook "remote-cb"
          #
          # This makes the compiler take a slightly different code path than if
          # the cookbook was just in the dep graphs.
          "remote-cb" => {
            "99.99.99" => [ ]
          },

          # This also conflicts, but only via the graphs
          "remote-cb-two" => {
            "1.2.3" => [ ]
          }

        }
      end

      context "and no explicit source is given for the conflicting cookbook" do

        before do
          # This is on the community site
          policyfile.dsl.cookbook("remote-cb")
        end

        it "raises an error describing the conflict" do
          repo_path = File.expand_path("path/to/repo")

          expected_err = <<-ERROR
Source supermarket(https://supermarket.chef.io) and chef_repo(#{repo_path}) contain conflicting cookbooks:
- remote-cb
- remote-cb-two
ERROR

          expect { policyfile.remote_artifacts_graph }.to raise_error do |error|
            expect(error).to be_a(ChefDK::CookbookSourceConflict)
            expect(error.message).to eq(expected_err)
          end
        end
      end

      context "and the conflicting cookbook has an explicit source in the Policyfile" do

        before do
          # This is on the community site
          policyfile.dsl.cookbook("remote-cb", path: "path/to/remote-cb")
          policyfile.dsl.cookbook("remote-cb-two", git: "git://git.example:user/remote-cb-two.git")
          policyfile.error!
        end

        it "solves the graph" do
          expect { policyfile.remote_artifacts_graph }.to_not raise_error
        end

        it "assigns the correct source options to the cookbook" do
          remote_cb_source_opts = policyfile.cookbook_location_spec_for("remote-cb").source_options
          expect(remote_cb_source_opts).to eq(path: "path/to/remote-cb")

          remote_cb_two_source_opts = policyfile.cookbook_location_spec_for("remote-cb-two").source_options
          expect(remote_cb_two_source_opts).to eq(git: "git://git.example:user/remote-cb-two.git")
        end
      end

    end

  end

end
