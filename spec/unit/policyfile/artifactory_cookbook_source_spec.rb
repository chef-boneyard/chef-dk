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
require "chef-dk/policyfile/source_uri"
require "chef-dk/policyfile/artifactory_cookbook_source"

describe ChefDK::Policyfile::ArtifactoryCookbookSource do
  subject { described_class.new(cookbook_source) }

  let(:cookbook_source) { "https://supermarket.chef.io/api/v1" }

  let(:http_connection) { double("Chef::HTTP::Simple") }

  let(:universe_response_encoded) { IO.read(File.join(fixtures_path, "cookbooks_api/small_universe.json")) }

  let(:pruned_universe) { JSON.parse(IO.read(File.join(fixtures_path, "cookbooks_api/pruned_small_universe.json"))) }

  describe "fetching the Universe graph" do

    before do
      expect(subject).to receive(:http_connection_for).with(cookbook_source).and_return(http_connection)
      allow(http_connection).to receive(:get).with("/universe").and_return(universe_response_encoded)
    end

    it "fetches the universe graph" do
      expect(http_connection).to receive(:get).with("/universe").and_return(universe_response_encoded)
      actual_universe = subject.universe_graph
      expect(actual_universe).to have_key("apt")
      expect(actual_universe["apt"]).to eq(pruned_universe["apt"])
      expect(subject.universe_graph).to eq(pruned_universe)
    end

    it "generates location options for a cookbook from the given graph" do
      cookbook_url = "https://supermarket.chef.io/api/v1/cookbooks/apache2/versions/1.10.4/download"
      expect(subject).to receive(:http_connection_for).with(cookbook_url).and_return(http_connection)
      expected_opts = {
        artifactory: cookbook_url,
        http_client: http_connection,
        version: "1.10.4",
      }
      expect(subject.source_options_for("apache2", "1.10.4")).to eq(expected_opts)
    end
  end
end
