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
require "chef-dk/cookbook_profiler/identifiers"
require "chef-dk/policyfile/read_cookbook_for_compat_mode_upload"

describe ChefDK::CookbookProfiler::Identifiers do

  let(:cache_path) do
    File.expand_path("spec/unit/fixtures/cookbook_cache", project_root)
  end

  let(:foo_cookbook_path) do
    File.join(cache_path, "foo-1.0.0")
  end

  let(:cookbook_version) do
    chefignore = Chef::Cookbook::Chefignore.new(File.join(foo_cookbook_path, "chefignore"))
    cbvl = Chef::Cookbook::CookbookVersionLoader.new(foo_cookbook_path, chefignore)
    cbvl.load!
    cbvl.cookbook_version
  end

  let(:identifiers) do
    ChefDK::CookbookProfiler::Identifiers.new(cookbook_version)
  end

  let(:cookbook_files_with_cksums) do
    # Entries must be sorted lexically.
    {
      ".kitchen.yml" => "85ba09a085dab072722cb197e04fa805",
      "README.md" => "0f15038071e5a131bef176cbe2a956d1",
      "chefignore" => "03485640b005eb1083c76518764053dd",
      "metadata.rb" => "4879d0004b177546cfbcfb2fd26df7c8",
      "recipes/default.rb" => "9a0f27d741deaca21461073f7452474f",
    }
  end

  it "has the cookbook's semver version" do
    expect(identifiers.semver_version).to eq("1.0.0")
  end

  it "lists the cookbook's files" do
    cookbook_files_with_cksums.each do |path, cksum|
      expect(identifiers.cookbook_files).to have_key(path)
      expect(identifiers.cookbook_files[path]["checksum"]).to eq(cksum)
    end
  end

  it "generates a sorted list of the cookbook's files with checksums" do
    # Verify that the keys are sorted in our expected data, otherwise our test
    # is wrong.
    expect(cookbook_files_with_cksums.keys).to eq(cookbook_files_with_cksums.keys.sort)
    expected = cookbook_files_with_cksums.map { |path, cksum| "#{path}:#{cksum}\n" }.join("")
    expect(identifiers.fingerprint_text).to eq(expected)
  end

  it "generates a Hash of the cookbook's content" do
    expect(identifiers.content_identifier).to eq("467dc855408ce8b74f991c5dc2fd72a6aa369b60")
  end

  it "generates a dotted decimal representation of the content hash" do
    expect(identifiers.dotted_decimal_identifier).to eq("19841547746970856.51597439762547453.126060145843040")
  end

end
