#
# Copyright:: Copyright (c) 2014-2018 Chef Software Inc.
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
require "chef-dk/policyfile/solution_dependencies"

describe ChefDK::Policyfile::SolutionDependencies do

  let(:dependency_data) { { "Policyfile" => [], "dependencies" => {} } }

  let(:solution_dependencies) do
    s = described_class.new
    s.consume_lock_data(dependency_data)
    s
  end

  it "has a list of dependencies declared in the Policyfile" do
    expect(solution_dependencies.policyfile_dependencies).to eq([])
  end

  it "has a map of dependencies declared by cookbooks" do
    expect(solution_dependencies.cookbook_dependencies).to eq({})
  end

  context "when populated with dependency data from a lockfile" do

    let(:dependency_data) do
      {
        "Policyfile" => [
          [ "nginx", "~> 1.0"], ["postgresql", ">= 0.0.0" ]
        ],
        "dependencies" => {
          "nginx (1.2.3)" => [ ["apt", "~> 2.3"], ["yum", "~>3.4"] ],
          "apt (2.5.6)" => [],
          "yum (3.4.1)" => [],
          "postgresql (5.0.0)" => [],
        },
      }
    end

    it "has a list of dependencies from the policyfile" do
      expected = [ "nginx", "~> 1.0"], ["postgresql", ">= 0.0.0" ]
      expect(solution_dependencies.policyfile_dependencies_for_lock).to eq(expected)
    end

    it "has a list of dependencies from cookbooks" do
      expected = {
        "nginx (1.2.3)" => [ ["apt", "~> 2.3"], ["yum", "~> 3.4"] ],
        "apt (2.5.6)" => [],
        "yum (3.4.1)" => [],
        "postgresql (5.0.0)" => [],
      }
      expect(solution_dependencies.cookbook_deps_for_lock).to eq(expected)
    end

  end

  context "when populated with dependency data from a complex lockfile" do
    let(:dependency_data) do
      {
        "Policyfile" => [
          [ "a", ">= 0.0.0"], ["b", ">= 0.0.0" ]
        ],
        "dependencies" => {
          "a (0.1.0)" => [ ["c", "~> 1.0.0"], ["d", "~> 0.0.0"] ],
          "b (1.0.0)" => [ ["f", ">= 0.0.1"] ],
          "c (1.0.1)" => [ ["e", ">= 0.0.1"] ],
          "d (0.0.1)" => [],
          "e (0.0.1)" => [],
          "f (0.0.1)" => [],
        },
      }
    end
    it "can compute list of transitive dependencies" do

      expect(solution_dependencies.transitive_deps(["e"])).to eq(["e"])
      expect(solution_dependencies.transitive_deps(["c"])).to eq(%w{c e})
      expect(solution_dependencies.transitive_deps(%w{c d})).to eq(%w{c d e})
      expect(solution_dependencies.transitive_deps(["a"])).to eq(%w{a c d e})
    end
  end

  context "when populated with dependency data" do

    let(:expected_deps_for_lock) do
      {
        "nginx (1.2.3)" => [ ["apt", "~> 2.3"], ["yum", "~> 3.4"] ],
        "apt (2.5.6)" => [],
        "yum (3.4.1)" => [],
        "postgresql (5.0.0)" => [],
      }
    end

    let(:expected_policyfile_deps_for_lock) do
      [ [ "nginx", "~> 1.0"], ["postgresql", ">= 0.0.0" ] ]
    end

    before do
      solution_dependencies.add_policyfile_dep("nginx", "~> 1.0")
      solution_dependencies.add_policyfile_dep("postgresql", ">= 0.0.0")
      solution_dependencies.add_cookbook_dep("nginx", "1.2.3", [ ["apt", "~> 2.3"], ["yum", "~>3.4"] ])
      solution_dependencies.add_cookbook_dep("apt", "2.5.6", [])
      solution_dependencies.add_cookbook_dep("yum", "3.4.1", [])
      solution_dependencies.add_cookbook_dep("postgresql", "5.0.0", [])
    end

    it "has a list of dependencies from the Policyfile" do
      expect(solution_dependencies.policyfile_dependencies_for_lock).to eq(expected_policyfile_deps_for_lock)
    end

    it "has a list of dependencies from cookbooks" do
      expect(solution_dependencies.cookbook_deps_for_lock).to eq(expected_deps_for_lock)
    end

    it "generates lock info containing both policyfile and cookbook dependencies" do
      expected = { "Policyfile" => expected_policyfile_deps_for_lock, "dependencies" => expected_deps_for_lock }
      expect(solution_dependencies.to_lock).to eq(expected)
    end

    describe "checking for dependency conflicts" do

      it "does not raise if a cookbook that's in the dependency set with a different version doesn't conflict" do
        solution_dependencies.update_cookbook_dep("yum", "3.5.0", [ ])
        expect(solution_dependencies.test_conflict!("yum", "3.5.0")).to be(false)
      end

      it "raises if a cookbook is not in the current solution set" do
        expected_message = "Cookbook foo (1.0.0) not in the working set, cannot test for conflicts"
        expect { solution_dependencies.test_conflict!("foo", "1.0.0") }.to raise_error(ChefDK::CookbookNotInWorkingSet, expected_message)
      end

      it "raises when a cookbook conflicts with a Policyfile constraint" do
        solution_dependencies.update_cookbook_dep("nginx", "2.0.0", [])

        expected_message = "Cookbook nginx (2.0.0) conflicts with other dependencies:\nPolicyfile depends on nginx ~> 1.0"
        expect { solution_dependencies.test_conflict!("nginx", "2.0.0") }.to raise_error(ChefDK::DependencyConflict, expected_message)
      end

      it "raises when a cookbook conflicts with another cookbook's dependency constraint" do
        solution_dependencies.update_cookbook_dep("apt", "3.0.0", [])

        expected_message = "Cookbook apt (3.0.0) conflicts with other dependencies:\nnginx (1.2.3) depends on apt ~> 2.3"
        expect { solution_dependencies.test_conflict!("apt", "3.0.0") }.to raise_error(ChefDK::DependencyConflict, expected_message)
      end

      it "raises when a cookbook's dependencies are no longer satisfiable" do
        solution_dependencies.update_cookbook_dep("nginx", "1.2.3", [ [ "apt", "~> 3.0" ] ])
        expected_message = "Cookbook nginx (1.2.3) has dependency constraints that cannot be met by the existing cookbook set:\n" +
          "Dependency on apt ~> 3.0 conflicts with existing version apt (2.5.6)"
        expect { solution_dependencies.test_conflict!("nginx", "1.2.3") }.to raise_error(ChefDK::DependencyConflict, expected_message)
      end

    end
  end

end
