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
require "chef-dk/policyfile/reports/install"

# Used for verifying doubles
require "chef-dk/policyfile_compiler"
require "chef-dk/policyfile/cookbook_location_specification"

describe ChefDK::Policyfile::Reports::Install do

  let(:ui) { TestHelpers::TestUI.new }

  let(:policyfile_compiler) { instance_double("ChefDK::PolicyfileCompiler") }

  subject(:install_report) { described_class.new(ui: ui, policyfile_compiler: policyfile_compiler ) }

  it "has a UI object" do
    expect(install_report.ui).to eq(ui)
  end

  it "has a policyfile compiler" do
    expect(install_report.policyfile_compiler).to eq(policyfile_compiler)
  end

  describe "when printing an installation report for fixed version cookbooks" do

    let(:fixed_version_cookbook_one) do
      instance_double("ChefDK::Policyfile::CookbookLocationSpecification",
                      installed?: false,
                      name: "short-name",
                      version_constraint: ">= 0.0.0",
                      source_type: :git)
    end

    let(:fixed_version_cookbook_two) do
      instance_double("ChefDK::Policyfile::CookbookLocationSpecification",
                      installed?: true,
                      name: "this-name-is-longer",
                      version_constraint: "~> 10.0.0",
                      source_type: :path)
    end

    let(:fixed_version_cookbooks) do
      { "short-name" => fixed_version_cookbook_one, "this-name-is-longer" => fixed_version_cookbook_two }
    end

    before do
      allow(policyfile_compiler).to receive(:fixed_version_cookbooks_specs).and_return(fixed_version_cookbooks)
    end

    it "prints a table-ized message for cookbooks being installed" do
      install_report.installing_fixed_version_cookbook(fixed_version_cookbook_one)
      expect(ui.output).to eq("Installing short-name          >= 0.0.0 from git\n")
    end

    it "prints a table-ized message for cookbooks in the cache that are reused" do
      install_report.installing_fixed_version_cookbook(fixed_version_cookbook_two)
      expect(ui.output).to eq("Using      this-name-is-longer ~> 10.0.0 from path\n")
    end

  end

  describe "when printing an installation report for normal dependencies" do

    let(:cookbook_one) do
      instance_double("ChefDK::Policyfile::CookbookLocationSpecification",
                      installed?: false,
                      name: "short-name",
                      version_constraint: Semverse::Constraint.new("= 10.0.4"))
    end

    let(:cookbook_two) do
      instance_double("ChefDK::Policyfile::CookbookLocationSpecification",
                      installed?: true,
                      name: "this-name-is-longer",
                      version_constraint: Semverse::Constraint.new("= 1.2.3"))
    end

    let(:graph_solution_cookbooks) do
      { "short-name" => "10.0.4", "this-name-is-longer" => "1.2.3" }
    end

    before do
      allow(policyfile_compiler).to receive(:graph_solution).and_return(graph_solution_cookbooks)
    end

    it "prints a table-ized message for cookbooks being installed" do
      install_report.installing_cookbook(cookbook_one)
      expect(ui.output).to eq("Installing short-name          10.0.4\n")
    end

    it "prints a table-ized message for cookbooks in the cache that are reused" do
      install_report.installing_cookbook(cookbook_two)
      expect(ui.output).to eq("Using      this-name-is-longer 1.2.3\n")
    end

  end
end
