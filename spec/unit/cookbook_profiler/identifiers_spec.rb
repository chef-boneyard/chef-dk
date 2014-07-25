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
require 'chef-dk/cookbook_profiler/identifiers'

describe ChefDK::CookbookProfiler::Identifiers do

  let(:cache_path) do
    File.expand_path("spec/unit/fixtures/cookbook_cache", project_root)
  end

  let(:foo_cookbook_path) do
    File.join(cache_path, "foo-1.0.0")
  end

  let(:identifiers) do
    ChefDK::CookbookProfiler::Identifiers.new(foo_cookbook_path)
  end

  let(:cookbook_files_with_cksums) do
    # Entries must be sorted lexically.
    {
      ".kitchen.yml" => "85ba09a085dab072722cb197e04fa805",
      "README.md" => "0f15038071e5a131bef176cbe2a956d1",
      "chefignore" => "03485640b005eb1083c76518764053dd",
      "metadata.rb" => "4879d0004b177546cfbcfb2fd26df7c8",
      "recipes/default.rb" => "9a0f27d741deaca21461073f7452474f"
    }
  end

  it "has the cookbook's path" do
    expect(identifiers.cookbook_path).to eq(foo_cookbook_path)
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
    expected = cookbook_files_with_cksums.map { |path,cksum| "#{path}:#{cksum}\n" }.join("")
    expect(identifiers.fingerprint_text).to eq(expected)
  end

  it "generates a Hash of the cookbook's content" do
    expect(identifiers.content_identifier).to eq("467dc855408ce8b74f991c5dc2fd72a6aa369b60")
  end

  it "generates a dotted decimal representation of the content hash" do
    expect(identifiers.dotted_decimal_identifier).to eq("19841547746970856.51597439762547453.126060145843040")
  end

  # The "foo" cookbook has an ignored file, but we test it explicitly to be
  # more resilient to changes in fixture data.
  context "when the cookbook has ignored files" do

    let(:copied_cookbook_path) { File.join(tempdir, "foo-1.0.0") }

    let(:chefignored_file) { File.join(copied_cookbook_path, "Guardfile") }

    let(:cp_cookbook_identifiers) do
      ChefDK::CookbookProfiler::Identifiers.new(copied_cookbook_path)
    end

    before do
      FileUtils.cp_r(foo_cookbook_path, copied_cookbook_path)
      File.open(chefignored_file, "w+") { |f| f.puts "This file should not affect the cookbooks checksum" }
    end

    after do
      clear_tempdir
    end


    it "ignores ignored files in the checksum calculation" do
      expect(cp_cookbook_identifiers.content_identifier).to eq(identifiers.content_identifier)
    end
  end

end

