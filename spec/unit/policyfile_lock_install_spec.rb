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
require 'chef-dk/policyfile_lock.rb'

describe ChefDK::PolicyfileLock, "installing cookbooks from a lockfile" do

  let(:cache_path) do
    File.expand_path("spec/unit/fixtures/cookbook_cache", project_root)
  end

  let(:policyfile_lock_path) { "/fakepath/Policyfile.lock.json" }

  let(:local_cookbooks_root) { File.join(fixtures_path, "local_path_cookbooks") }

  let(:name) { "application-server" }

  let(:run_list) { [ 'recipe[erlang::default]', 'recipe[erchef::prereqs]', 'recipe[erchef::app]' ] }

  let(:lock_generator) do
    ChefDK::PolicyfileLock.build({cache_path: cache_path, relative_paths_root: local_cookbooks_root}) do |policy|

      policy.name = name

      policy.run_list = run_list

      policy.cached_cookbook("foo") do |c|
        c.origin = "https://artifact-server.example/foo/1.0.0"
        c.cache_key = "foo-1.0.0"
        c.source_options = { artifactserver: "https://artifact-server.example/foo/1.0.0", version: "1.0.0" }
      end

      policy.local_cookbook("local-cookbook") do |c|
        c.source = "local-cookbook"
        c.source_options = { path: "local-cookbook" }
      end

    end
  end

  let(:lock_data) do
    lock_generator.to_lock
  end

  let(:policyfile_lock) do
    ChefDK::PolicyfileLock.new.build_from_lock_data(lock_data, policyfile_lock_path)
  end

  describe "Populating a PolicyfileLock from a lockfile data structure" do

    it "imports the name attribute" do
      expect(policyfile_lock.name).to eq(name)
    end

    it "imports the run_list attribute" do
      expect(policyfile_lock.run_list).to eq(run_list)
    end

    it "imports cached cookbook lock data" do
      expect(policyfile_lock.cookbook_locks).to have_key("foo")
      cookbook_lock = policyfile_lock.cookbook_locks["foo"]
      expect(cookbook_lock.name).to eq("foo")
      expect(cookbook_lock.cache_key).to eq("foo-1.0.0")
      expect(cookbook_lock.version).to eq("1.0.0")
      expect(cookbook_lock.identifier).to eq("e4611e9b5ec0636a18979e7dd22537222a2eab47")
      expect(cookbook_lock.dotted_decimal_identifier).to eq("64283078773620835.29863387009503781.60619876117319")
      expect(cookbook_lock.origin).to eq("https://artifact-server.example/foo/1.0.0")
      expect(cookbook_lock.source_options).to eq({ artifactserver: "https://artifact-server.example/foo/1.0.0", version: "1.0.0" })
      expect(cookbook_lock.version_constraint).to eq(Semverse::Constraint.new("= 1.0.0"))
    end

    it "imports local cookbook lock data" do
      expect(policyfile_lock.cookbook_locks).to have_key("local-cookbook")
      cookbook_lock = policyfile_lock.cookbook_locks["local-cookbook"]
      expect(cookbook_lock.name).to eq("local-cookbook")
      expect(cookbook_lock.version).to eq("2.3.4")
      expect(cookbook_lock.identifier).to eq("c72670948830f5e41f0b96fa088b7a37d21ad5d6")
      expect(cookbook_lock.dotted_decimal_identifier).to eq("56055785335566581.64210429328099467.134380166763990")
      expect(cookbook_lock.source).to eq("local-cookbook")
      expect(cookbook_lock.source_options).to eq({ path: "local-cookbook" })
      expect(cookbook_lock.version_constraint).to eq(Semverse::Constraint.new("= 2.3.4"))
    end

  end

  describe "installing cookbooks" do

    let(:remote_cookbook_lock) { policyfile_lock.cookbook_locks["foo"] }

    let(:local_cookbook_lock) { policyfile_lock.cookbook_locks["local-cookbook"] }

    it "configures the installer for a remote cookbook" do
      installer = remote_cookbook_lock.installer
      expect(installer).to be_an_instance_of(CookbookOmnifetch::ArtifactserverLocation)
      expect(installer.uri).to eq("https://artifact-server.example/foo/1.0.0")
      expect(installer.cookbook_version).to eq("1.0.0")
    end

    it "configures the installer for a local cookbook" do
      installer = local_cookbook_lock.installer
      expect(installer).to be_an_instance_of(CookbookOmnifetch::PathLocation)

      # Would like to verify that the correct path option was passed to
      # PathLocation.new() but there is no accessor for it.
      #expect(installer.path).to eq("local-cookbook")
    end

    context "when the cookbooks are not installed" do

      before do
        expect(remote_cookbook_lock.installer).to receive(:installed?).and_return(false)
        expect(local_cookbook_lock.installer).to receive(:installed?).and_return(false)
      end

      it "installs them" do
        expect(remote_cookbook_lock.installer).to receive(:install)
        expect(local_cookbook_lock.installer).to receive(:install)

        policyfile_lock.install_cookbooks
      end

    end

    context "when the cookbooks are installed" do

      before do
        expect(remote_cookbook_lock.installer).to receive(:installed?).and_return(true)
        expect(local_cookbook_lock.installer).to receive(:installed?).and_return(true)
      end

      it "verifies they are installed" do
        expect(remote_cookbook_lock.installer).to_not receive(:install)
        expect(local_cookbook_lock.installer).to_not receive(:install)

        policyfile_lock.install_cookbooks
      end
    end
  end

end


