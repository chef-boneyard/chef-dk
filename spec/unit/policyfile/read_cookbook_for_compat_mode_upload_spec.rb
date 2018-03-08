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
require "chef-dk/policyfile/read_cookbook_for_compat_mode_upload"
require "chef-dk/helpers"

describe ChefDK::Policyfile::ReadCookbookForCompatModeUpload do

  include ChefDK::Helpers

  let(:cookbook_name) { "noignore" }

  let(:version_override) { "123.456.789" }

  let(:directory_path) { File.join(fixtures_path, "local_path_cookbooks/noignore-f59ee7a5bca6a4e606b67f7f856b768d847c39bb") }

  let(:reader) { described_class.new(cookbook_name, version_override, directory_path) }

  it "has a cookbook_name" do
    expect(reader.cookbook_name).to eq(cookbook_name)
  end

  it "has a version number override" do
    expect(reader.version_override).to eq(version_override)
  end

  it "has a directory path" do
    expect(reader.directory_path).to eq(directory_path)
  end

  it "has an empty chefignore when the cookbook doesn't include one" do
    expect(reader.chefignore.ignores).to eq([])
  end

  it "loads the cookbook with the correct name" do
    expect(reader.cookbook_version.name).to eq(:noignore)
  end

  it "loads the cookbook with the correct version" do
    expect(reader.cookbook_version.version).to eq(version_override)
  end

  it "freezes the cookbook version" do
    expect(reader.cookbook_version.frozen_version?).to be true
  end

  it "fixes up the cookbook manifest name" do
    expect(reader.cookbook_version.manifest["name"]).to eq("noignore-#{version_override}")
  end

  context "when a cookbook has a chefignore file" do

    let(:directory_path) { File.join(fixtures_path, "cookbook_cache/baz-f59ee7a5bca6a4e606b67f7f856b768d847c39bb") }

    let(:copied_cookbook_path) { File.join(tempdir, "baz-f59ee7a5bca6a4e606b67f7f856b768d847c39bb") }

    let(:chefignored_file) { File.join(copied_cookbook_path, "Guardfile") }

    let(:reader_with_ignored_files) do
      described_class.new(cookbook_name, version_override, copied_cookbook_path)
    end

    before do
      FileUtils.cp_r(directory_path, copied_cookbook_path)
      with_file(chefignored_file) { |f| f.puts "This file should not affect the cookbooks checksum" }
    end

    after do
      clear_tempdir
    end

    it "excludes ignored files from the list of cookbook files" do
      expect(reader_with_ignored_files.cookbook_version.files_for("root_files")).to_not include(chefignored_file)
    end

  end
end
