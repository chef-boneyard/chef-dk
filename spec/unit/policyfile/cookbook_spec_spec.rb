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
require 'chef-dk/policyfile/cookbook_spec'

describe ChefDK::Policyfile::CookbookSpec do

  let(:policyfile_filename) { File.join(fixtures_path, "example_app/Policyfile.rb") }

  let(:version_constraint) { ">= 0.0.0" }

  let(:cookbook_name) { "my_cookbook" }

  let(:source_options) { {} }

  let(:cached_cookbook) { double("ChefDK::CookbookMetadata") }

  let(:installer) { double("CookbookOmnifetch location", cached_cookbook: cached_cookbook) }

  let(:storage_config) do
    ChefDK::Policyfile::StorageConfig.new.use_policyfile(policyfile_filename)
  end

  let(:cookbook_spec) { described_class.new(cookbook_name, version_constraint, source_options, storage_config) }

  it "has a name" do
    expect(cookbook_spec.name).to eq(cookbook_name)
  end

  it "has a version constraint" do
    expect(cookbook_spec.version_constraint).to eq(Semverse::Constraint.new(version_constraint))
  end

  it "has source options it was created with" do
    expect(cookbook_spec.source_options).to eq(source_options)
  end

  it "is equal to another cookbook spec with the same name, constraint, and options" do
    equal_spec = described_class.new(cookbook_name, version_constraint, source_options, storage_config)
    expect(cookbook_spec).to eq(equal_spec)
  end

  it "is not equal to another cookbook spec if the name, constraint or option differ" do
    different_name = described_class.new("wut", version_constraint, source_options, storage_config)
    expect(cookbook_spec).to_not eq(different_name)

    different_constraint = described_class.new(cookbook_name, ">= 1.0.0", source_options, storage_config)
    expect(cookbook_spec).to_not eq(different_constraint)

    different_opts = described_class.new(cookbook_name, version_constraint, {git: "git://example.com/wat.git"}, storage_config)
    expect(cookbook_spec).to_not eq(different_opts)
  end

  it "gives the base directory from which relative paths will be expanded" do
    expect(cookbook_spec.relative_paths_root).to eq(File.join(fixtures_path, "example_app"))
  end

  it "gives source options for locking via the installer" do
    lock_data = double("Installer lock data")
    expect(installer).to receive(:lock_data).and_return(lock_data)
    expect(cookbook_spec).to receive(:installer).and_return(installer)
    expect(cookbook_spec.to_source_options).to eq(lock_data)
  end

  describe "fetching and querying a cookbook" do

    before do
      expect(CookbookOmnifetch).to receive(:init).with(cookbook_spec, source_options).and_return(installer)
    end

    it "initializes a CookbookOmnifetch location class to handle installation" do
      expect(cookbook_spec.installer).to eq(installer)
    end

    it "delegates installation to the installer" do
      expect(installer).to receive(:installed?).and_return(false)
      expect(installer).to receive(:install)
      cookbook_spec.ensure_cached
    end

    it "does not install the cookbook if it's already cached" do
      expect(installer).to receive(:installed?).and_return(true)
      expect(installer).to_not receive(:install)
      cookbook_spec.ensure_cached
    end

    it "delegates cache_key to the installer" do
      expect(installer).to receive(:cache_key).and_return("my_cookbook-1.2.3-supermarket.getchef.com")
      expect(cookbook_spec.cache_key).to eq("my_cookbook-1.2.3-supermarket.getchef.com")
    end

    it "delegates relative_path to the installer" do
      expect(installer).to receive(:relative_path).and_return(Pathname.new("../my_stuff/my_cookbook"))
      expect(cookbook_spec.relative_path).to eq("../my_stuff/my_cookbook")
    end

    it "loads the cookbook metadata via the installer" do
      expect(cookbook_spec.cached_cookbook).to eq(cached_cookbook)
    end

    it "gives the cookbook's version via the metadata" do
      expect(cached_cookbook).to receive(:version).and_return("1.2.3")
      expect(cookbook_spec.version).to eq("1.2.3")
    end

    it "gives the cookbook's dependencies via the metadata" do
      expect(cached_cookbook).to receive(:dependencies).and_return("apt" => "~> 1.2.3")
      expect(cookbook_spec.dependencies).to eq("apt" => "~> 1.2.3")
    end

  end

  describe "when created with no source" do

    it "has a nil installer" do
      expect(cookbook_spec.installer).to be_nil
    end

    it "is not at a fixed version" do
      expect(cookbook_spec.version_fixed?).to be false
    end

  end

  describe "when created with a git source" do

    let(:source_options) { { git: "git@github.com:example/my_cookbook.git" } }

    it "has a git installer" do
      expect(cookbook_spec.installer).to be_a_kind_of(CookbookOmnifetch::GitLocation)
    end

    it "has a fixed version" do
      expect(cookbook_spec.version_fixed?).to be true
    end

    it "mirrors a canonical upstream" do
      expect(cookbook_spec.mirrors_canonical_upstream?).to be true
    end

  end

  describe "when created with a github source" do

    let(:source_options) { { github: "my_org/my_cookbook" } }

    it "has a github installer" do
      expect(cookbook_spec.installer).to be_a_kind_of(CookbookOmnifetch::GithubLocation)
    end

    it "has a fixed version" do
      expect(cookbook_spec.version_fixed?).to be true
    end

    it "mirrors a canonical upstream" do
      expect(cookbook_spec.mirrors_canonical_upstream?).to be true
    end

  end

  describe "when created with a path source" do

    let(:source_options) { { path: "../example_cookbook" } }

    it "has a path installer" do
      expect(cookbook_spec.installer).to be_a_kind_of(CookbookOmnifetch::PathLocation)
    end

    it "has a fixed version" do
      expect(cookbook_spec.version_fixed?).to be true
    end

    it "isnt a mirror of a canonical upstream" do
      expect(cookbook_spec.mirrors_canonical_upstream?).to be false
    end

  end

  describe "when created with an artifactserver source" do

    let(:source_options) { { artifactserver: "https://supermarket.getchef.com:/api/v1/cookbooks/my_cookbook/versions/2.0.0/download" } }

    it "has a artifactserver installer" do
      expect(cookbook_spec.installer).to be_a_kind_of(CookbookOmnifetch::ArtifactserverLocation)
    end

    it "does not have a fixed version" do
      expect(cookbook_spec.version_fixed?).to be false
    end

    it "is a mirror of a canonical upstream" do
      expect(cookbook_spec.mirrors_canonical_upstream?).to be true
    end

  end
end
