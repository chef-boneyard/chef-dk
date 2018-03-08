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
require "chef-dk/cookbook_metadata"

describe ChefDK::CookbookMetadata do

  describe "providing the API required by CookbookOmnifetch" do

    let(:metadata) { ChefDK::CookbookMetadata.new }

    it "provides a `from_path` class method" do
      expect(described_class).to respond_to(:from_path)
    end

    it "responds to #cookbook_name" do
      expect(metadata).to respond_to(:cookbook_name)
    end

    it "responds to #version" do
      expect(metadata).to respond_to(:version)
    end

  end

  describe "when a cookbook is loaded" do

    let(:cookbook) { described_class.from_path(cookbook_root) }

    context "and the cookbook has only a metadata.rb" do

      let(:cookbook_root) { File.join(fixtures_path, "example_cookbook") }

      it "has a name" do
        expect(cookbook.name).to eq("example_cookbook")
        expect(cookbook.cookbook_name).to eq("example_cookbook")
      end

      it "has a version" do
        expect(cookbook.version).to eq("0.1.0")
      end

      it "has a map of dependencies" do
        expect(cookbook.dependencies).to eq({})
      end

    end

    context "and the cookbook has only a metadata.json" do

      let(:cookbook_root) { File.join(fixtures_path, "example_cookbook_metadata_json_only") }

      it "has a name" do
        expect(cookbook.name).to eq("example_cookbook")
        expect(cookbook.cookbook_name).to eq("example_cookbook")
      end

      it "has a version" do
        expect(cookbook.version).to eq("0.1.0")
      end

      it "has a map of dependencies" do
        expect(cookbook.dependencies).to eq({})
      end

    end

    context "and the cookbook has no metadata" do

      let(:cookbook_root) { File.join(fixtures_path, "example_cookbook_no_metadata") }

      it "raises a MalformedCookbook error" do
        msg = "Cookbook at #{cookbook_root} has neither metadata.json or metadata.rb"

        expect { cookbook }.to raise_error(ChefDK::MalformedCookbook, msg)
      end

    end

  end
end
