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

      allow(p.default_source).to receive(:universe_graph).and_return(external_cookbook_universe)
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

end
