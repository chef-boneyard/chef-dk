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
require "chef-dk/policyfile/community_cookbook_source"

describe ChefDK::Policyfile::CommunityCookbookSource do

  subject(:cookbook_source) { ChefDK::Policyfile::CommunityCookbookSource.new }

  let(:default_community_uri) { "https://supermarket.chef.io" }

  let(:http_connection) { double("Chef::HTTP::Simple") }

  let(:universe_response_encoded) { IO.read(File.join(fixtures_path, "cookbooks_api/small_universe.json")) }

  let(:pruned_universe) { JSON.parse(IO.read(File.join(fixtures_path, "cookbooks_api/pruned_small_universe.json"))) }

  it "defaults to using the public supermarket over HTTPS" do
    expect(cookbook_source.uri).to eq(default_community_uri)
  end

  it "gives the set of arguments to `default_source` used to create it" do
    expect(cookbook_source.default_source_args).to eq([:supermarket, default_community_uri])
  end

  describe "fetching the Universe graph over HTTP" do

    before do
      expect(Chef::HTTP::Simple).to receive(:new).with(default_community_uri).and_return(http_connection)
      expect(http_connection).to receive(:get).with("/universe").and_return(universe_response_encoded)
    end

    it "fetches the universe graph" do
      actual_universe = cookbook_source.universe_graph
      expect(actual_universe).to have_key("apt")
      expect(actual_universe["apt"]).to eq(pruned_universe["apt"])
      expect(cookbook_source.universe_graph).to eq(pruned_universe)
    end

    it "generates location options for a cookbook from the given graph" do
      expected_opts = { artifactserver: "https://supermarket.chef.io/api/v1/cookbooks/apache2/versions/1.10.4/download", version: "1.10.4" }
      expect(cookbook_source.source_options_for("apache2", "1.10.4")).to eq(expected_opts)
    end

  end

  context "when created with a block to set source preferences" do

    subject(:cookbook_source) do
      ChefDK::Policyfile::CommunityCookbookSource.new do |s|
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
