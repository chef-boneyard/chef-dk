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
require "chef-dk/policyfile/storage_config"

describe ChefDK::Policyfile::StorageConfig do

  let(:config_options) { {} }

  let(:storage_config) do
    described_class.new(config_options)
  end

  context "with explicit path options" do

    let(:cache_path) do
      File.expand_path("spec/unit/fixtures/cookbook_cache", project_root)
    end

    let(:relative_paths_root) do
      File.expand_path("spec/unit/fixtures/", project_root)
    end

    let(:config_options) do
      { cache_path: cache_path, relative_paths_root: relative_paths_root }
    end

    it "uses the provided option for relative_paths_root" do
      expect(storage_config.relative_paths_root).to eq(relative_paths_root)
    end

    it "uses the provided cache_path" do
      expect(storage_config.cache_path).to eq(cache_path)
    end
  end

  context "with default options" do

    it "defaults to the CookbookOmnifetch configured cache path" do
      expect(storage_config.cache_path).to eq(CookbookOmnifetch.storage_path)
    end

    it "defaults to the current working directory for relative_paths_root" do
      expect(storage_config.relative_paths_root).to eq(Dir.pwd)
    end
  end

  describe "updating storage config for policyfile location" do

    before do
      storage_config.use_policyfile("/path/to/Policyfile.rb")
    end

    it "updates the relative_paths_root to be relative to a policyfile" do
      expect(storage_config.relative_paths_root).to eq("/path/to")
    end

    it "stores the location of the policyfile" do
      expect(storage_config.policyfile_filename).to eq("/path/to/Policyfile.rb")
    end

    it "generates the location of the policyfile lock" do
      expect(storage_config.policyfile_lock_filename).to eq("/path/to/Policyfile.lock.json")
    end

    it "gives the expanded path to the policyfile" do
      expect(storage_config.policyfile_expanded_path).to eq(File.expand_path("/path/to/Policyfile.rb"))
    end

    context "when the policyfile is given as a relative path" do

      before do
        storage_config.use_policyfile("Policyfile.rb")
      end

      it "updates the relative_paths_root to be relative to a policyfile" do
        expect(storage_config.relative_paths_root).to eq(".")
      end

      it "stores the location of the policyfile" do
        expect(storage_config.policyfile_filename).to eq("Policyfile.rb")
      end

      it "generates the location of the policyfile lock" do
        expect(storage_config.policyfile_lock_filename).to eq("Policyfile.lock.json")
      end

      it "gives the expanded path to the policyfile" do
        expect(storage_config.policyfile_expanded_path).to eq(File.expand_path("Policyfile.rb", "."))
      end

    end

    context "when the policyfile file name doesn't have a .rb extension" do

      it "raises an error" do
        err_string = %q{Policyfile filenames must end with `.rb' extension (you gave: `Policyfile')}
        expect { storage_config.use_policyfile("Policyfile") }.to raise_error(ChefDK::InvalidPolicyfileFilename, err_string)
      end

    end

    context "when the policyfile file name is actually a lockfile" do

      before do
        storage_config.use_policyfile("foo.lock.json")
      end

      it "uses the policyfile .rb file instead" do
        expect(storage_config.policyfile_filename).to eq("foo.rb")
      end

    end

  end

  describe "updating storage config for policyfile lock location" do

    before do
      storage_config.use_policyfile_lock("/path/to/Policyfile.lock.json")
    end

    it "updates the relative_paths_root to be relative to a policyfile" do
      expect(storage_config.relative_paths_root).to eq("/path/to")
    end

    it "stores the location of the policyfile lock" do
      expect(storage_config.policyfile_lock_filename).to eq("/path/to/Policyfile.lock.json")
    end

    it "stores the location of the policyfile" do
      expect(storage_config.policyfile_filename).to eq("/path/to/Policyfile.rb")
    end

    it "gives the expanded path to the policyfile lock" do
      expect(storage_config.policyfile_lock_expanded_path).to eq(File.expand_path("/path/to/Policyfile.lock.json"))
    end

    context "when given a relative path to the policyfile lock" do

      before do
        storage_config.use_policyfile_lock("Policyfile.lock.json")
      end

      it "updates the relative_paths_root to be relative to a policyfile" do
        expect(storage_config.relative_paths_root).to eq(".")
      end

      it "stores the location of the policyfile" do
        expect(storage_config.policyfile_filename).to eq("Policyfile.rb")
      end

      it "generates the location of the policyfile lock" do
        expect(storage_config.policyfile_lock_filename).to eq("Policyfile.lock.json")
      end

      it "gives the expanded path to the policyfile" do
        expect(storage_config.policyfile_lock_expanded_path).to eq(File.expand_path("Policyfile.lock.json", "."))
      end

    end

  end

end
