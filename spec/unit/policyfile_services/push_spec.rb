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

require "spec_helper"
require "chef-dk/policyfile_services/push"

describe ChefDK::PolicyfileServices::Push do

  include ChefDK::Helpers

  let(:working_dir) do
    path = File.join(tempdir, "policyfile_services_test_working_dir")
    Dir.mkdir(path)
    path
  end

  let(:policyfile_rb_explicit_name) { nil }

  let(:policyfile_rb_name) { policyfile_rb_explicit_name || "Policyfile.rb" }

  let(:policyfile_lock_name) { "Policyfile.lock.json" }

  let(:policyfile_rb_path) { File.join(working_dir, policyfile_rb_name) }

  let(:policyfile_lock_path) { File.join(working_dir, policyfile_lock_name) }

  let(:policy_group) { "staging-cluster-1" }

  let(:local_cookbooks_root) do
    File.join(fixtures_path, "local_path_cookbooks")
  end

  let(:policy_document_native_api) { false }

  let(:config) do
    double("Chef::Config",
           chef_server_url: "https://localhost:10443",
           client_key: "/path/to/client/key.pem",
           node_name: "deuce",
           policy_document_native_api: policy_document_native_api)
  end

  let(:ui) { TestHelpers::TestUI.new }

  let(:push_service) { described_class.new(policyfile: policyfile_rb_name, policy_group: policy_group, ui: ui, config: config, root_dir: working_dir) }

  it "configures an HTTP client" do
    expect(Chef::ServerAPI).to receive(:new).with("https://localhost:10443",
                                                       signing_key_filename: "/path/to/client/key.pem",
                                                       client_name: "deuce")
    push_service.http_client
  end

  it "infers the path to Policyfile.lock.json" do
    expect(push_service.policyfile_lock_expanded_path).to eq(policyfile_lock_path)
  end

  it "has a storage configuration" do
    storage_config = push_service.storage_config
    expect(storage_config.policyfile_lock_filename).to eq(policyfile_lock_path)
    expect(storage_config.relative_paths_root).to eq(working_dir)
  end

  context "when given an explicit path to the policyfile" do

    let(:policyfile_rb_name) { "MyPolicy.rb" }

    let(:policyfile_lock_name) { "MyPolicy.lock.json" }

    it "infers the path to the lockfile from the policyfile location" do
      expect(push_service.policyfile_lock_expanded_path).to eq(policyfile_lock_path)
    end

  end

  context "when given a path to a Policyfile.lock.json instead of an rb" do

    let(:policyfile_rb_name) { "MyPolicy.rb" }

    let(:policyfile_lock_name) { "MyPolicy.lock.json" }

    let(:push_service) { described_class.new(policyfile: policyfile_lock_name, policy_group: policy_group, ui: ui, config: config, root_dir: working_dir) }

    it "loads the correct policyfile" do
      storage_config = push_service.storage_config
      expect(storage_config.policyfile_lock_filename).to eq(policyfile_lock_path)
      expect(storage_config.policyfile_filename).to eq(policyfile_rb_path)
    end

  end

  context "when no lockfile is present" do

    it "errors out" do
      expect { push_service.run }.to raise_error(ChefDK::LockfileNotFound)
    end

  end

  context "when a lockfile is present" do

    before do
      with_file(policyfile_lock_path) { |f| f.print(lockfile_content) }
    end

    context "and the lockfile has invalid JSON" do

      let(:lockfile_content) { ":::" }

      it "errors out" do
        expect { push_service.run }.to raise_error(ChefDK::PolicyfilePushError)
      end

    end

    context "and the lockfile is semantically invalid" do

      let(:lockfile_content) { "{ }" }

      it "errors out" do
        expect { push_service.run }.to raise_error(ChefDK::PolicyfilePushError)
      end

    end

    context "and the lockfile is valid" do

      let(:local_cookbook_path) { File.join(fixtures_path, "local_path_cookbooks/local-cookbook") }

      let(:lockfile_content) do
        <<-E
{
  "name": "install-example",
  "run_list": [
    "recipe[local-cookbook::default]"
  ],
  "cookbook_locks": {
    "local-cookbook": {
      "version": "2.3.4",
      "identifier": "fab501cfaf747901bd82c1bc706beae7dc3a350c",
      "dotted_decimal_identifier": "70567763561641081.489844270461035.258281553147148",
      "source": "#{local_cookbook_path}",
      "cache_key": null,
      "scm_info": null,
      "source_options": {
        "path": "#{local_cookbook_path}"
      }
    }
  },
  "default_attributes": {},
  "override_attributes": {},
  "solution_dependencies": {
    "Policyfile": [
      [
        "local-cookbook",
        ">= 0.0.0"
      ]
    ],
    "dependencies": {
      "local-cookbook (2.3.4)": [

      ]
    }
  }
}
E
      end

      let(:http_client) { instance_double(Chef::ServerAPI) }

      let(:updated_lockfile_io) { StringIO.new }

      let(:uploader) { instance_double(ChefDK::Policyfile::Uploader) }

      before do
        expect(push_service).to receive(:http_client).and_return(http_client)

        expect(ChefDK::Policyfile::Uploader).to receive(:new).
               with(push_service.policyfile_lock, policy_group, http_client: http_client, ui: ui, policy_document_native_api: policy_document_native_api).
               and_return(uploader)
      end

      context "when the policy document native API is disabled" do

        it "configures a Policyfile Uploader" do
          push_service.uploader
        end

        it "validates the lockfile, writes any updates, and uploads the cookbooks" do
          allow(File).to receive(:open).and_call_original
          expect(File).to receive(:open).with(policyfile_lock_path, "wb+").and_yield(updated_lockfile_io)
          expect(uploader).to receive(:upload)

          push_service.run
        end

      end

      context "when the policy document native API is enabled" do

        let(:policy_document_native_api) { true }

        it "configures a Policyfile Uploader with the policy document native API option" do
          push_service.uploader
        end

        it "validates the lockfile, writes any updates, and uploads the cookbooks" do
          allow(File).to receive(:open).and_call_original
          expect(File).to receive(:open).with(policyfile_lock_path, "wb+").and_yield(updated_lockfile_io)
          expect(uploader).to receive(:upload)

          push_service.run
        end

      end

      describe "when an error occurs in upload" do

        before do
          allow(File).to receive(:open).and_call_original
          expect(File).to receive(:open).with(policyfile_lock_path, "wb+").and_yield(updated_lockfile_io)
          expect(uploader).to receive(:upload).and_raise("an error")
        end

        it "raises an error" do
          expect { push_service.run }.to raise_error(ChefDK::PolicyfilePushError)
        end

      end

    end

  end

end
