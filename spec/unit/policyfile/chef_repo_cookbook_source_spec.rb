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
require "chef-dk/policyfile/chef_repo_cookbook_source"

describe ChefDK::Policyfile::ChefRepoCookbookSource do

  let(:repo_path) do
    File.expand_path("spec/unit/fixtures/local_path_cookbooks", project_root)
  end

  let(:cookbook_source) { ChefDK::Policyfile::ChefRepoCookbookSource.new(repo_path) }

  let(:local_repo_universe) do
    {
      "another-local-cookbook" => {
        "0.1.0" => [],
      },
      "local-cookbook" => {
        "2.3.4" => [],
      },
      "cookbook-with-a-dep" => {
        "9.9.9" => [["another-local-cookbook", "~> 0.1"]],
      },
      "noignore" => {
        "0.1.0" => [],
      },
    }
  end

  it "gives the set of arguments to `default_source` used to create it" do
    expect(cookbook_source.default_source_args).to eq([:chef_repo, repo_path])
  end

  it "fetches the universe graph" do
    actual_universe = cookbook_source.universe_graph
    expect(actual_universe).to eql(local_repo_universe)
  end

  it "generates location options for a cookbook from the given graph" do
    expected_opts = { path: File.join(repo_path, "local-cookbook"), version: "2.3.4" }
    expect(cookbook_source.source_options_for("local-cookbook", "2.3.4")).to eq(expected_opts)
  end

  it "will append a cookbooks directory to the path if it finds it" do
    expect(Dir).to receive(:exist?).with("#{repo_path}/cookbooks").and_return(true)
    expect(cookbook_source.path).to eql("#{repo_path}/cookbooks")
  end

  it "the private setter will append a cookbooks directory to the path if finds it" do
    expect(cookbook_source.path).to eql(repo_path)
    expect(Dir).to receive(:exist?).with("#{repo_path}/cookbooks").and_return(true)
    cookbook_source.send(:path=, repo_path)
    expect(cookbook_source.path).to eql("#{repo_path}/cookbooks")
  end

  context "when created with a block to set source preferences" do

    subject(:cookbook_source) do
      described_class.new(repo_path) do |s|
        s.preferred_for "foo", "bar", "baz"
      end
    end

    it "sets the source preferences as given" do
      expect(cookbook_source.preferred_cookbooks).to eq( %w{ foo bar baz } )
    end

    it "is the preferred source for the requested cookbooks" do
      expect(cookbook_source.preferred_source_for?("foo")).to be(true)
      expect(cookbook_source.preferred_source_for?("bar")).to be(true)
      expect(cookbook_source.preferred_source_for?("baz")).to be(true)
      expect(cookbook_source.preferred_source_for?("razzledazzle")).to be(false)
    end

  end

end
