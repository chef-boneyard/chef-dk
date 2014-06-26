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
require 'chef-dk/cookbook_cache_manager'

describe ChefDK::CookbookCacheManager do

  def new_cache_manager(options={})
    ChefDK::CookbookCacheManager.new(policyfile, options)
  end

  let(:cache_path) { tempdir }

  let(:policyfile) { ChefDK::PolicyfileCompiler.new }

  let(:cache_manager) { ChefDK::CookbookCacheManager.new(policyfile) }

  before do
    reset_tempdir
  end

  describe "handling initialization options" do

    it "sets a cache path" do
      expect(cache_manager.cache_path).to eq(CookbookOmnifetch.storage_path)
    end

  end

  context "when the community site is the default source" do

    before do
      policyfile.dsl.default_source(:community)
    end

    let(:default_community_uri) { "https://supermarket.getchef.com" }

    let(:http_connection) { double("Chef::HTTP::Simple") }

    let(:universe_response_encoded) { IO.read(File.join(fixtures_path, "cookbooks_api/small_universe.json")) }

    let(:pruned_universe) { JSON.parse(IO.read(File.join(fixtures_path, "cookbooks_api/pruned_small_universe.json"))) }

    before do
      expect(Chef::HTTP::Simple).to receive(:new).with(default_community_uri).and_return(http_connection)
      expect(http_connection).to receive(:get).with("/universe").and_return(universe_response_encoded)
    end

    it "fetches the universe graph" do
      actual_universe = cache_manager.universe_graph
      expect(actual_universe).to have_key("apt")
      expect(actual_universe["apt"]).to eq(pruned_universe["apt"])
      expect(cache_manager.universe_graph).to eq(pruned_universe)
    end

    it "generates location options for a cookbook from the given graph" do
      expected_opts = { artifactserver: "http://cookbooks.opscode.com/api/v1", version: "1.10.4" }
      expect(cache_manager.source_options_for("apache2", "1.10.4")).to eq(expected_opts)
    end

  end

  context "when chef-server is the default source" do

    before do
      policyfile.dsl.default_source(:chef_server, "https://chef.example.com")
    end

    it "emits a not supported error" do
      expect { cache_manager.universe_graph }.to raise_error(ChefDK::UnsupportedFeature)
    end

  end

  context "when the default source is not specified" do

    it "emits an empty graph" do
      expect(cache_manager.universe_graph).to eq({})
    end

  end

end

