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
require 'chef-dk/policyfile/chef_repo_cookbook_source'

describe ChefDK::Policyfile::ChefRepoCookbookSource do

  let(:repo_path) {
    File.expand_path("spec/unit/fixtures/local_path_cookbooks", project_root)
  }

  let(:cookbook_source) { ChefDK::Policyfile::ChefRepoCookbookSource.new(repo_path) }

  let(:local_repo_universe) {
    {
      "another-local-cookbook"=>{
        "0.1.0"=>[],
      },
      "local-cookbook"=>{
        "2.3.4"=>[],
      },
      "cookbook-with-a-dep"=>{
        "9.9.9"=>[["another-local-cookbook", "~> 0.1"]],
      },
      "noignore"=>{
        "0.1.0"=>[],
      },
    }
  }
  it "fetches the universe graph" do
    actual_universe = cookbook_source.universe_graph
    expect(actual_universe).to eql(local_repo_universe)
  end

  it "generates location options for a cookbook from the given graph" do
    expected_opts = { path: File.join(repo_path, "local-cookbook"), version: "2.3.4" }
    expect(cookbook_source.source_options_for("local-cookbook", "2.3.4")).to eq(expected_opts)
  end

end
