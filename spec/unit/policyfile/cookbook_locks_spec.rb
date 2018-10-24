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
require "chef-dk/policyfile/cookbook_locks"

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

  context "when the underlying cookbook has not been mutated, or #refresh! has not been called" do

    it "is not updated" do
      expect(cookbook_lock).to_not be_updated
    end

    it "does not have an updated identifier" do
      expect(cookbook_lock.identifier_updated?).to be false
    end

    it "does not have an updated version" do
      expect(cookbook_lock.version_updated?).to be false
    end

  end

  context "when version and identifier attributes are populated" do

    before do
      allow(cookbook_lock).to receive(:validate!)

      cookbook_lock.identifier = "my-opaque-id"
      cookbook_lock.dotted_decimal_identifier = "123.456.789"
      cookbook_lock.version = "1.2.3"
      cookbook_lock.source_options = { sourcekey: "location info" }
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
      expect(cookbook_lock_data["source_options"]).to eq({ sourcekey: "location info" })
    end

    it "creates a CookbookLocationSpecification with the source and version data" do
      location_spec = cookbook_lock.cookbook_location_spec
      expect(location_spec.name).to eq(cookbook_name)
      expect(location_spec.version_constraint).to eq(Semverse::Constraint.new("= 1.2.3"))
      expect(location_spec.source_options).to eq({ sourcekey: "location info" })
    end

    it "delegates #dependencies to cookbook_location_spec" do
      deps = [ [ "foo", ">= 0.0.0"], [ "bar", "~> 2.1" ] ]
      expect(cookbook_lock.cookbook_location_spec).to receive(:dependencies).and_return(deps)
      expect(cookbook_lock.dependencies).to eq(deps)
    end

    it "delegates #installed? to the CookbookLocationSpecification" do
      location_spec = cookbook_lock.cookbook_location_spec
      expect(location_spec).to receive(:installed?).and_return(true)
      expect(cookbook_lock).to be_installed
      expect(location_spec).to receive(:installed?).and_return(false)
      expect(cookbook_lock).to_not be_installed
    end

  end

  context "when created from lock data" do

    let(:lock_data) do
      {
        "identifier" => "my-opaque-id",
        "dotted_decimal_identifier" => "123.456.789",
        "version" => "1.2.3",
        "source_options" => { "sourcekey" => "location info" },
        "cache_key" => nil,
        "source" => "cookbooks_local_path",
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

  it "ignores calls to #refresh!" do
    expect { cookbook_lock.refresh! }.to_not raise_error
  end

  context "when populated with valid data" do

    let(:cookbook_name) { "foo" }

    let(:cache_path) { File.join(fixtures_path, "cached_cookbooks") }

    before do
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

  let(:scm_profiler) { instance_double("ChefDK::CookbookProfiler::Git", profile_data: {}) }

  let(:cookbook_lock) do
    lock = described_class.new(cookbook_name, storage_config)
    allow(lock).to receive(:scm_profiler).and_return(scm_profiler)
    lock
  end

  include_examples "Cookbook Lock"

  describe "gathering identifier info" do
    let(:identifiers) do
      instance_double("ChefDK::CookbookProfiler::Identifiers",
                     content_identifier: "abc123",
                     dotted_decimal_identifier: "111.222.333",
                     semver_version: "1.2.3")
    end

    before do
      allow(cookbook_lock).to receive(:identifiers).and_return(identifiers)
      cookbook_lock.gather_profile_data
    end

    it "sets the content identifier" do
      expect(cookbook_lock.identifier).to eq("abc123")
    end

    it "sets the backwards compatible dotted decimal identifer equivalent" do
      expect(cookbook_lock.dotted_decimal_identifier).to eq("111.222.333")
    end

    it "collects the 'real' SemVer version of the cookbook" do
      expect(cookbook_lock.version).to eq("1.2.3")
    end

  end

  describe "selecting an SCM profiler" do

    let(:cookbook_source_relpath) { "nginx" }

    let(:cookbook_source_path) do
      path = File.join(tempdir, cookbook_source_relpath)
      FileUtils.mkdir_p(path)
      path
    end

    # everywhere else, #scm_profiler is stubbed, we need the unstubbed version
    let(:cookbook_lock) do
      described_class.new(cookbook_name, storage_config)
    end

    before do
      cookbook_lock.source = cookbook_source_path
    end

    after do
      clear_tempdir
    end

    context "when the cookbook is in a git-repo" do

      before do
        FileUtils.mkdir_p(git_dir_path)
      end

      context "when the cookbook is a self-contained git repo" do

        let(:git_dir_path) { File.join(cookbook_source_path, ".git") }

        it "selects the git profiler" do
          expect(cookbook_lock.scm_profiler).to be_an_instance_of(ChefDK::CookbookProfiler::Git)
        end

      end

      context "when the cookbook is a subdirectory of a git repo" do

        let(:cookbook_source_relpath) { "cookbook_repo/nginx" }

        let(:git_dir_path) { File.join(tempdir, "cookbook_repo/.git") }

        it "selects the git profiler" do
          expect(cookbook_lock.scm_profiler).to be_an_instance_of(ChefDK::CookbookProfiler::Git)
        end

      end

    end

    context "when the cookbook is not in a git repo" do

      it "selects the null profiler" do
        expect(cookbook_lock.scm_profiler).to be_an_instance_of(ChefDK::CookbookProfiler::NullSCM)
      end

    end

  end

  context "when loading data from a serialized form" do

    let(:previous_lock_data) do
      {
        "identifier" => "abc123",
        "dotted_decimal_identifier" => "111.222.333",
        "version" => "1.2.3",
        "source" => "../my_repo/nginx",
        "source_options" => {
          "path" => "../my_repo/nginx",
        },
        "cache_key" => nil,
      }
    end

    before do
      cookbook_lock.build_from_lock_data(previous_lock_data)
    end

    it "sets the identifier" do
      expect(cookbook_lock.identifier).to eq("abc123")
    end

    it "sets the dotted_decimal_identifier" do
      expect(cookbook_lock.dotted_decimal_identifier).to eq("111.222.333")
    end

    it "sets the version" do
      expect(cookbook_lock.version).to eq("1.2.3")
    end

    it "sets the source attribute" do
      expect(cookbook_lock.source).to eq("../my_repo/nginx")
    end

    it "sets the source options, symbolizing keys so the data is compatible with CookbookLocationSpecification" do
      expected = { path: "../my_repo/nginx" }
      expect(cookbook_lock.source_options).to eq(expected)
    end

    it "doesn't refresh scm_data when #lock_data is called" do
      allow(scm_profiler).to receive(:profile_data).and_raise("This shouldn't get called")
      cookbook_lock.lock_data
    end

    context "after the data has been refreshed" do

      before do
        allow(cookbook_lock).to receive(:identifiers).and_return(identifiers)
        cookbook_lock.refresh!
      end

      context "and the underlying hasn't been mutated" do

        let(:identifiers) do
          instance_double("ChefDK::CookbookProfiler::Identifiers",
                         content_identifier: "abc123",
                         dotted_decimal_identifier: "111.222.333",
                         semver_version: "1.2.3")
        end

        it "has the correct identifier" do
          expect(cookbook_lock.identifier).to eq("abc123")
        end

        it "has the correct dotted_decimal_identifier" do
          expect(cookbook_lock.dotted_decimal_identifier).to eq("111.222.333")
        end

        it "has the correct version" do
          expect(cookbook_lock.version).to eq("1.2.3")
        end

        it "sets the updated flag to false" do
          expect(cookbook_lock).to_not be_updated
        end

        it "sets the version_updated flag to false" do
          expect(cookbook_lock.version_updated?).to be(false)
        end

        it "sets the identifier_updated flag to false" do
          expect(cookbook_lock.identifier_updated?).to be(false)
        end

      end

      context "and the underlying data has been mutated" do
        # represents the updated state of the cookbook
        let(:identifiers) do
          instance_double("ChefDK::CookbookProfiler::Identifiers",
                         content_identifier: "def456",
                         dotted_decimal_identifier: "777.888.999",
                         semver_version: "7.8.9")
        end

        it "sets the content identifier to the new identifier" do
          expect(cookbook_lock.identifier).to eq("def456")
        end

        it "sets the dotted_decimal_identifier to the new identifier" do
          expect(cookbook_lock.dotted_decimal_identifier).to eq("777.888.999")
        end

        it "sets the SemVer version to the new version" do
          expect(cookbook_lock.version).to eq("7.8.9")
        end

        it "sets the updated flag to true" do
          expect(cookbook_lock).to be_updated
        end

        it "sets the version_updated flag to true" do
          expect(cookbook_lock.version_updated?).to be(true)
        end

        it "sets the identifier_updated flag to true" do
          expect(cookbook_lock.identifier_updated?).to be(true)
        end
      end
    end
  end

end

describe ChefDK::Policyfile::ArchivedCookbook do

  let(:cookbook_name) { "nginx" }

  let(:storage_config) { ChefDK::Policyfile::StorageConfig.new }

  let(:wrapped_cookbook_lock_data) do
    {
      "identifier" => "abc123",
      "dotted_decimal_identifier" => "111.222.333",
      "version" => "1.2.3",
      "source" => "../my_repo/nginx",
      "source_options" => {
        # when getting the cookbook location spec, source options needs to have
        # symbolic keys, so a round trip via LocalCookbook#build_from_lock_data
        # will result in this being a symbol
        path: "../my_repo/nginx",
      },
      "cache_key" => nil,
      "scm_info" => {},
    }
  end

  let(:wrapped_cookbook_lock) do
    lock = ChefDK::Policyfile::LocalCookbook.new(cookbook_name, storage_config)
    allow(lock).to receive(:scm_info).and_return({})
    lock.build_from_lock_data(wrapped_cookbook_lock_data)
    lock
  end

  let(:cookbook_lock) do
    described_class.new(wrapped_cookbook_lock, storage_config)
  end

  let(:archived_cookbook_path) { File.join(storage_config.relative_paths_root, "cookbook_artifacts", "nginx-abc123") }

  it "sets cookbook_path to the path within the archive" do
    expect(cookbook_lock.cookbook_path).to eq(archived_cookbook_path)
  end

  it "implements build_from_lock_data" do
    msg = "ArchivedCookbook cannot be built from lock data, it can only wrap an existing lock object"
    expect { cookbook_lock.build_from_lock_data({}) }.to raise_error(NotImplementedError, msg)
  end

  it "implements validate!" do
    expect(cookbook_lock.validate!).to be(true)
  end

  it "implements refresh!" do
    expect(cookbook_lock.refresh!).to be(true)
  end

  it "implements installed?" do
    allow(File).to receive(:exist?).with(archived_cookbook_path).and_return(false)
    allow(File).to receive(:directory?).with(archived_cookbook_path).and_return(false)
    expect(cookbook_lock.installed?).to be(false)
    allow(File).to receive(:exist?).with(archived_cookbook_path).and_return(true)
    allow(File).to receive(:directory?).with(archived_cookbook_path).and_return(true)
    expect(cookbook_lock.installed?).to be(true)
  end

  describe "delegated behavior" do

    it "sets the identifier" do
      expect(cookbook_lock.identifier).to eq("abc123")
    end

    it "sets the dotted_decimal_identifier" do
      expect(cookbook_lock.dotted_decimal_identifier).to eq("111.222.333")
    end

    it "sets the version" do
      expect(cookbook_lock.version).to eq("1.2.3")
    end

    it "sets the source attribute" do
      expect(cookbook_lock.source).to eq("../my_repo/nginx")
    end

    it "sets the source options, symbolizing keys so the data is compatible with CookbookLocationSpecification" do
      expected = { path: "../my_repo/nginx" }
      expect(cookbook_lock.source_options).to eq(expected)
    end

    it "returns unchanged data when calling to_lock" do
      expect(cookbook_lock.to_lock).to eq(wrapped_cookbook_lock_data)
    end

  end

end
