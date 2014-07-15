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
require 'chef-dk/policyfile/cookbook_locks'

shared_examples_for "Cookbook Lock" do

  let(:cookbook_lock_data) { cookbook_lock.to_lock }

  it "has a cookbook name" do
    expect(cookbook_lock.name).to eq(cookbook_name)
  end

  it "has a source_options attribute" do
    cookbook_lock.source_options = { artifactserver: "https://artifacts.example.com/nginx/1.0.0/download" }
    expect(cookbook_lock.source_options).to eq({ artifactserver: "https://artifacts.example.com/nginx/1.0.0/download" })
  end

  it "has an identifier attribute" do
    cookbook_lock.identifier = "my-opaque-id"
    expect(cookbook_lock.identifier).to eq("my-opaque-id")
  end

  it "has a dotted_decimal_identifier attribute" do
    cookbook_lock.dotted_decimal_identifier = "123.456.789"
    expect(cookbook_lock.dotted_decimal_identifier).to eq("123.456.789")
  end

  it "has a version attribute" do
    cookbook_lock.version = "1.2.3"
    expect(cookbook_lock.version).to eq("1.2.3")
  end

  it "has a storage config" do
    expect(cookbook_lock.storage_config).to eq(storage_config)
  end

  context "when version and identifier attributes are populated" do

    before do
      allow(cookbook_lock).to receive(:validate!)
      allow(cookbook_lock).to receive(:scm_info).and_return({})

      cookbook_lock.identifier = "my-opaque-id"
      cookbook_lock.dotted_decimal_identifier = "123.456.789"
      cookbook_lock.version = "1.2.3"
      cookbook_lock.source_options = { :sourcekey => "location info" }
    end

    it "includes the identifier in the lock data" do
      expect(cookbook_lock_data["identifier"]).to eq("my-opaque-id")
    end

    it "includes the dotted decimal identifier in the lock data" do
      expect(cookbook_lock_data["dotted_decimal_identifier"]).to eq("123.456.789")
    end

    it "includes the version in lock data" do
      expect(cookbook_lock_data["version"]).to eq("1.2.3")
    end

    it "includes the source_options in lock data" do
      expect(cookbook_lock_data["source_options"]).to eq({ :sourcekey => "location info" })
    end

    it "creates a CookbookLocationSpecification with the source and version data" do
      location_spec = cookbook_lock.cookbook_location_spec
      expect(location_spec.name).to eq(cookbook_name)
      expect(location_spec.version_constraint).to eq(Semverse::Constraint.new("= 1.2.3"))
      expect(location_spec.source_options).to eq({ sourcekey: "location info" })
    end

  end

  context "when created from lock data" do

    let(:lock_data) do
      {
        "identifier" => "my-opaque-id",
        "dotted_decimal_identifier" => "123.456.789",
        "version" => "1.2.3",
        "source_options" => { "sourcekey" => "location info" }
      }
    end

    before do
      cookbook_lock.build_from_lock_data(lock_data)
    end

    it "sets the identifier attribute" do
      expect(cookbook_lock.identifier).to eq("my-opaque-id")
    end

    it "sets the dotted_decimal_identifier attribute" do
      expect(cookbook_lock.dotted_decimal_identifier).to eq("123.456.789")
    end

    it "sets the version attribute" do
      expect(cookbook_lock.version).to eq("1.2.3")
    end

    it "sets the source options" do
      expect(cookbook_lock.source_options).to eq({ sourcekey: "location info" })
    end
  end

end


describe ChefDK::Policyfile::CachedCookbook do

  let(:cookbook_name) { "nginx" }

  let(:storage_config) { ChefDK::Policyfile::StorageConfig.new }

  let(:cookbook_lock) do
    described_class.new(cookbook_name, storage_config)
  end

  include_examples "Cookbook Lock"

  it "has a cache_key attribute" do
    cookbook_lock.cache_key = "nginx-1.0.0-example.com"
    expect(cookbook_lock.cache_key).to eq("nginx-1.0.0-example.com")
  end

  it "has an origin attribute" do
    cookbook_lock.origin = "https://artifacts.example.com/nginx/1.0.0/download"
    expect(cookbook_lock.origin).to eq("https://artifacts.example.com/nginx/1.0.0/download")
  end

  it "errors locating the cookbook when the cache key is not set" do
    expect { cookbook_lock.cookbook_path }.to raise_error(ChefDK::MissingCookbookLockData)
  end

  context "when populated with valid data" do

    let(:cookbook_name) { "foo" }

    let(:cache_path) { File.join(fixtures_path, "cached_cookbooks") }

    before do
      # cookbook_lock.identifier = "my-opaque-id"
      # cookbook_lock.dotted_decimal_identifier = "123.456.789"
      # cookbook_lock.version = "1.0.0"
      # cookbook_lock.source_options = { :sourcekey => "location info" }
      cookbook_lock.cache_key = "foo-1.0.0"

      storage_config.cache_path = cache_path
    end

    it "gives the path to the cookbook in the cache" do
      expect(cookbook_lock.cookbook_path).to eq(File.join(cache_path, "foo-1.0.0"))
    end

  end

end

describe ChefDK::Policyfile::LocalCookbook do

  let(:cookbook_name) { "nginx" }

  let(:storage_config) { ChefDK::Policyfile::StorageConfig.new }

  let(:cookbook_lock) do
    described_class.new(cookbook_name, storage_config)
  end

  include_examples "Cookbook Lock"

end
