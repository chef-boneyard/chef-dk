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
require "chef-dk/policyfile/cookbook_location_specification"

describe ChefDK::Policyfile::CookbookLocationSpecification do

  let(:policyfile_filename) { File.join(fixtures_path, "example_app/Policyfile.rb") }

  let(:version_constraint) { ">= 0.0.0" }

  let(:cookbook_name) { "my_cookbook" }

  let(:source_options) { {} }

  let(:cached_cookbook) { double("ChefDK::CookbookMetadata") }

  let(:install_path) { Pathname.new("~/.chefdk/cache/cookbooks/my_cookbook-1.0.0") }

  let(:installer) { double("CookbookOmnifetch location", cached_cookbook: cached_cookbook, install_path: install_path) }

  let(:storage_config) do
    ChefDK::Policyfile::StorageConfig.new.use_policyfile(policyfile_filename)
  end

  let(:cookbook_location_spec) { described_class.new(cookbook_name, version_constraint, source_options, storage_config) }

  it "has a name" do
    expect(cookbook_location_spec.name).to eq(cookbook_name)
  end

  it "has a version constraint" do
    expect(cookbook_location_spec.version_constraint).to eq(Semverse::Constraint.new(version_constraint))
  end

  it "has source options it was created with" do
    expect(cookbook_location_spec.source_options).to eq(source_options)
  end

  it "is equal to another cookbook spec with the same name, constraint, and options" do
    equal_spec = described_class.new(cookbook_name, version_constraint, source_options, storage_config)
    expect(cookbook_location_spec).to eq(equal_spec)
  end

  it "is not equal to another cookbook spec if the name, constraint or option differ" do
    different_name = described_class.new("wut", version_constraint, source_options, storage_config)
    expect(cookbook_location_spec).to_not eq(different_name)

    different_constraint = described_class.new(cookbook_name, ">= 1.0.0", source_options, storage_config)
    expect(cookbook_location_spec).to_not eq(different_constraint)

    different_opts = described_class.new(cookbook_name, version_constraint, { git: "git://example.com/wat.git" }, storage_config)
    expect(cookbook_location_spec).to_not eq(different_opts)
  end

  it "gives the base directory from which relative paths will be expanded" do
    expect(cookbook_location_spec.relative_paths_root).to eq(File.join(fixtures_path, "example_app"))
  end

  it "gives source options for locking via the installer" do
    lock_data = double("Installer lock data")
    expect(installer).to receive(:lock_data).and_return(lock_data)
    expect(cookbook_location_spec).to receive(:installer).and_return(installer)
    expect(cookbook_location_spec.source_options_for_lock).to eq(lock_data)
  end

  it "converts to a readable string with all relevant info" do
    expected_s = "Cookbook 'my_cookbook' >= 0.0.0"
    expect(cookbook_location_spec.to_s).to eq(expected_s)
  end

  describe "fetching and querying a cookbook" do

    before do
      expect(CookbookOmnifetch).to receive(:init).with(cookbook_location_spec, source_options).and_return(installer)
    end

    it "initializes a CookbookOmnifetch location class to handle installation" do
      expect(cookbook_location_spec.installer).to eq(installer)
    end

    it "delegates #installed? to the installer" do
      expect(installer).to receive(:installed?).and_return(false)
      expect(cookbook_location_spec).to_not be_installed
      expect(installer).to receive(:installed?).and_return(true)
      expect(cookbook_location_spec).to be_installed
    end

    it "delegates installation to the installer" do
      expect(installer).to receive(:installed?).and_return(false)
      expect(installer).to receive(:install)
      cookbook_location_spec.ensure_cached
    end

    it "does not install the cookbook if it's already cached" do
      expect(installer).to receive(:installed?).and_return(true)
      expect(installer).to_not receive(:install)
      cookbook_location_spec.ensure_cached
    end

    it "delegates cache_key to the installer" do
      expect(installer).to receive(:cache_key).and_return("my_cookbook-1.2.3-supermarket.chef.io")
      expect(cookbook_location_spec.cache_key).to eq("my_cookbook-1.2.3-supermarket.chef.io")
    end

    it "delegates relative_path to the installer" do
      expect(installer).to receive(:relative_path).and_return(Pathname.new("../my_stuff/my_cookbook"))
      expect(cookbook_location_spec.relative_path).to eq("../my_stuff/my_cookbook")
    end

    it "loads the cookbook metadata via the installer" do
      expect(cookbook_location_spec.cached_cookbook).to eq(cached_cookbook)
    end

    it "gives the cookbook's version via the metadata" do
      expect(cached_cookbook).to receive(:version).and_return("1.2.3")
      expect(cookbook_location_spec.version).to eq("1.2.3")
    end

    it "gives the cookbook's dependencies via the metadata" do
      expect(cached_cookbook).to receive(:dependencies).and_return("apt" => "~> 1.2.3")
      expect(cookbook_location_spec.dependencies).to eq("apt" => "~> 1.2.3")
    end

    it "determines whether a cookbook has a given recipe" do
      cookbook_path = cookbook_location_spec.cookbook_path
      # "cache" cookbook_path so we stub the correct object
      allow(cookbook_location_spec).to receive(:cookbook_path).and_return(cookbook_path)

      default_recipe_path = install_path.join("recipes/default.rb")
      nope_recipe_path = install_path.join("recipes/nope.rb")

      expect(cookbook_path).to receive(:join).with("recipes/default.rb").and_return(default_recipe_path)
      expect(cookbook_path).to receive(:join).with("recipes/nope.rb").and_return(nope_recipe_path)

      expect(default_recipe_path).to receive(:exist?).and_return(true)
      expect(nope_recipe_path).to receive(:exist?).and_return(false)

      expect(cookbook_location_spec.cookbook_has_recipe?("default")).to be(true)
      expect(cookbook_location_spec.cookbook_has_recipe?("nope")).to be(false)
    end

  end

  describe "when created with no source" do

    it "has a nil installer" do
      expect(cookbook_location_spec.installer).to be_nil
    end

    it "is not at a fixed version" do
      expect(cookbook_location_spec.version_fixed?).to be false
    end

  end

  describe "when created with invalid source options" do

    let(:source_options) { { herp: "derp" } }

    it "is invalid" do
      expect(cookbook_location_spec).to_not be_valid
      expect(cookbook_location_spec.errors.size).to eq(1)
      error = cookbook_location_spec.errors.first
      expect(error).to eq("Cookbook `my_cookbook' has invalid source options `{:herp=>\"derp\"}'")
    end

  end

  describe "when created with a git source" do

    let(:source_options) { { git: "git@github.com:example/my_cookbook.git" } }

    it "has a git installer" do
      expect(cookbook_location_spec.installer).to be_a_kind_of(CookbookOmnifetch::GitLocation)
    end

    it "has a fixed version" do
      expect(cookbook_location_spec.version_fixed?).to be true
    end

    it "mirrors a canonical upstream" do
      expect(cookbook_location_spec.mirrors_canonical_upstream?).to be true
    end

    it "is valid" do
      expect(cookbook_location_spec.errors.size).to eq(0)
      expect(cookbook_location_spec).to be_valid
    end

  end

  describe "when created with a github source" do

    let(:source_options) { { github: "my_org/my_cookbook" } }

    it "has a github installer" do
      expect(cookbook_location_spec.installer).to be_a_kind_of(CookbookOmnifetch::GithubLocation)
    end

    it "has a fixed version" do
      expect(cookbook_location_spec.version_fixed?).to be true
    end

    it "mirrors a canonical upstream" do
      expect(cookbook_location_spec.mirrors_canonical_upstream?).to be true
    end

    it "is valid" do
      expect(cookbook_location_spec.errors.size).to eq(0)
      expect(cookbook_location_spec).to be_valid
    end

  end

  describe "when created with a path source" do

    let(:source_options) { { path: "../example_cookbook" } }

    it "has a path installer" do
      expect(cookbook_location_spec.installer).to be_a_kind_of(CookbookOmnifetch::PathLocation)
    end

    it "has a fixed version" do
      expect(cookbook_location_spec.version_fixed?).to be true
    end

    it "isnt a mirror of a canonical upstream" do
      expect(cookbook_location_spec.mirrors_canonical_upstream?).to be false
    end

    it "is valid" do
      expect(cookbook_location_spec.errors.size).to eq(0)
      expect(cookbook_location_spec).to be_valid
    end

  end

  describe "when created with an artifactserver source" do

    let(:source_options) { { artifactserver: "https://supermarket.chef.io:/api/v1/cookbooks/my_cookbook/versions/2.0.0/download" } }

    it "has a artifactserver installer" do
      expect(cookbook_location_spec.installer).to be_a_kind_of(CookbookOmnifetch::ArtifactserverLocation)
    end

    it "does not have a fixed version" do
      expect(cookbook_location_spec.version_fixed?).to be false
    end

    it "is a mirror of a canonical upstream" do
      expect(cookbook_location_spec.mirrors_canonical_upstream?).to be true
    end

    it "is valid" do
      expect(cookbook_location_spec.errors.size).to eq(0)
      expect(cookbook_location_spec).to be_valid
    end

  end

  describe "when created with a chef_server source" do

    let(:source_options) { { chef_server: "https://api.opscode.com/organizations/chef-oss-dev/cookbooks/my_cookbook/versions/2.0.0/download" } }

    let(:http_client) { instance_double("ChefDK::ChefServerAPIMulti") }

    before do
      CookbookOmnifetch.integration.default_chef_server_http_client = http_client
    end

    after do
      CookbookOmnifetch.integration.default_chef_server_http_client = nil
    end

    it "has a chef_server installer" do
      expect(cookbook_location_spec.installer).to be_a_kind_of(CookbookOmnifetch::ChefServerLocation)
    end

    it "does not have a fixed version" do
      expect(cookbook_location_spec.version_fixed?).to be false
    end

    it "is a mirror of a canonical upstream" do
      expect(cookbook_location_spec.mirrors_canonical_upstream?).to be true
    end

    it "is valid" do
      expect(cookbook_location_spec.errors.size).to eq(0)
      expect(cookbook_location_spec).to be_valid
    end

  end

  describe "when created with a chef_server_artifact source" do

    let(:source_options) do
      {
        chef_server_artifact: "https://api.opscode.com/organizations/chef-oss-dev/",
        identifier: "09d43fad354b3efcc5b5836fef5137131f60f974",
      }
    end

    let(:http_client) { instance_double("ChefDK::ChefServerAPIMulti") }

    before do
      CookbookOmnifetch.integration.default_chef_server_http_client = http_client
    end

    after do
      CookbookOmnifetch.integration.default_chef_server_http_client = nil
    end

    it "has a chef_server_artifact installer" do
      expect(cookbook_location_spec.installer).to be_a_kind_of(CookbookOmnifetch::ChefServerArtifactLocation)
    end

    it "does has a fixed version" do
      expect(cookbook_location_spec.version_fixed?).to be(true)
    end

    it "is a mirror of a canonical upstream" do
      expect(cookbook_location_spec.mirrors_canonical_upstream?).to be(true)
    end

    it "is valid" do
      expect(cookbook_location_spec.errors.size).to eq(0)
      expect(cookbook_location_spec).to be_valid
    end

  end
end
