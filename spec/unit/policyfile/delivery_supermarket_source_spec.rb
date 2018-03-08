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
require "chef-dk/policyfile/delivery_supermarket_source"

describe ChefDK::Policyfile::DeliverySupermarketSource do

  let(:supermarket_uri) { "https://delivery-supermarket.example" }

  subject(:cookbook_source) { ChefDK::Policyfile::DeliverySupermarketSource.new(supermarket_uri) }

  let(:http_connection) { double("Chef::HTTP::Simple") }

  let(:universe_response_encoded) { IO.read(File.join(fixtures_path, "cookbooks_api/small_universe.json")) }

  let(:truncated_universe) do
    {
      "nginx" => {
        "2.7.4" => {
          "apt" => "~> 2.2.0",
          "bluepill" => "~> 2.3.0",
          "build-essential" => "~> 2.0.0",
          "ohai" => "~> 2.0.0",
          "runit" => "~> 1.2.0",
          "yum-epel" => "~> 0.3.0",
        },
      },
      "mysql" => {
        "5.3.6" => {
          "yum-mysql-community" => ">= 0.0.0",
        },
      },
      "application" => {
        "4.1.4" => {},
      },
      "database" => {
        "2.2.0" => {
          "mysql" => ">= 5.0.0",
          "postgresql" => ">= 1.0.0",
          "aws" => ">= 0.0.0",
          "xfs" => ">= 0.0.0",
          "mysql-chef_gem" => ">= 0.0.0",
        },
      },
      "postgresql" => {
        "3.4.1" => {
          "apt" => ">= 1.9.0",
          "build-essential" => ">= 0.0.0",
          "openssl" => ">= 0.0.0",
        },
      },
      "apache2" => {
        "1.10.4" => {
          "iptables" => ">= 0.0.0",
          "logrotate" => ">= 0.0.0",
          "pacman" => ">= 0.0.0",
        },
      },
      "apt" => { "2.4.0" => {} },
      "yum" => { "3.2.2" => {} },
    }
  end

  it "uses `delivery_supermarket` it its description" do
    expect(cookbook_source.desc).to eq("delivery_supermarket(https://delivery-supermarket.example)")
  end

  it "gives the set of arguments to `default_source` used to create it" do
    expect(cookbook_source.default_source_args).to eq([:delivery_supermarket, supermarket_uri])
  end

  describe "when fetching the /universe graph" do

    before do
      expect(Chef::HTTP::Simple).to receive(:new).with(supermarket_uri).and_return(http_connection)
      expect(http_connection).to receive(:get).with("/universe").and_return(universe_response_encoded)
    end

    it "fetches the universe graph and truncates to only the latest versions" do
      actual_universe = cookbook_source.universe_graph
      expect(actual_universe).to have_key("apt")
      expect(actual_universe["apt"]).to eq(truncated_universe["apt"])
      expect(cookbook_source.universe_graph).to eq(truncated_universe)
    end

    it "generates location options for a cookbook from the given graph" do
      expected_opts = { artifactserver: "https://supermarket.chef.io/api/v1/cookbooks/apache2/versions/1.10.4/download", version: "1.10.4" }
      expect(cookbook_source.source_options_for("apache2", "1.10.4")).to eq(expected_opts)
    end

  end

  context "when created with a block to set source preferences" do

    subject(:cookbook_source) do
      described_class.new(supermarket_uri) do |s|
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
