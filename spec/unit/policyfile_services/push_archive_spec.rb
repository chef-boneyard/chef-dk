#
# Copyright:: Copyright (c) 2015 Chef Software Inc.
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
require "chef-dk/policyfile_services/push_archive"

describe ChefDK::PolicyfileServices::PushArchive do

  FileToTar = Struct.new(:name, :content)

  def create_archive
    Zlib::GzipWriter.open(archive_file_path) do |gz_file|
      Archive::Tar::Minitar::Writer.open(gz_file) do |tar|

        archive_dirs.each do |dir|
          tar.mkdir(dir, mode: 0755)
        end

        archive_files.each do |file|
          name = file.name
          content = file.content
          size = content.bytesize
          tar.add_file_simple(name, mode: 0644, size: size) { |f| f.write(content) }
        end

      end
    end
  end

  let(:valid_lockfile) do
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
      "source": "project-cookbooks/local-cookbook",
      "cache_key": null,
      "scm_info": null,
      "source_options": {
        "path": "project-cookbooks/local-cookbook"
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

  let(:archive_files) { [] }

  let(:archive_dirs) { [] }

  let(:working_dir) do
    path = File.join(tempdir, "policyfile_services_test_working_dir")
    Dir.mkdir(path)
    path
  end

  let(:archive_file_name) { "example-policy-abc123.tgz" }

  let(:archive_file_path) { File.join(working_dir, archive_file_name) }

  let(:policy_group) { "dev-cluster-1" }

  let(:config) do
    double("Chef::Config",
           chef_server_url: "https://localhost:10443",
           client_key: "/path/to/client/key.pem",
           node_name: "deuce",
           policy_document_native_api: true)
  end

  let(:ui) { TestHelpers::TestUI.new }

  subject(:push_archive_service) do
    described_class.new(archive_file: archive_file_name,
                        policy_group: policy_group,
                        root_dir: working_dir,
                        ui: ui,
                        config: config)
  end

  it "has an archive file" do
    expect(push_archive_service.archive_file).to eq(archive_file_name)
    expect(push_archive_service.archive_file_path).to eq(archive_file_path)
  end

  it "configures an HTTP client" do
    expect(Chef::ServerAPI).to receive(:new).with("https://localhost:10443",
                                                       signing_key_filename: "/path/to/client/key.pem",
                                                       client_name: "deuce")
    push_archive_service.http_client
  end

  context "with an invalid archive" do

    let(:exception) do
      begin
        push_archive_service.run
      rescue ChefDK::PolicyfilePushArchiveError => e
        e
      else
        nil
      end
    end

    let(:exception_cause) { exception.cause }

    context "when the archive is malformed/corrupted/etc" do

      context "when the archive file doesn't exist" do

        it "errors out" do
          expect(exception).to_not be_nil
          expect(exception.message).to eq("Failed to publish archived policy")
          expect(exception_cause).to be_a(ChefDK::InvalidPolicyArchive)
          expect(exception_cause.message).to eq("Archive file #{archive_file_path} not found")
        end
      end

      context "when the archive is not a gzip file" do

        before do
          FileUtils.touch(archive_file_path)
        end

        it "errors out" do
          expect(exception).to_not be_nil
          expect(exception.message).to eq("Failed to publish archived policy")
          expect(exception_cause).to be_a(ChefDK::InvalidPolicyArchive)
          expect(exception_cause.message).to eq("Archive file #{archive_file_path} could not be unpacked. not in gzip format")
        end

      end

      context "when the archive is a gzip file of a garbage file" do

        before do
          Zlib::GzipWriter.open(archive_file_path) do |gz_file|
            gz_file << "lol this isn't a tar file"
          end
        end

        it "errors out" do
          expect(exception).to_not be_nil
          expect(exception.message).to eq("Failed to publish archived policy")
          expect(exception_cause).to be_a(ChefDK::InvalidPolicyArchive)
          expect(exception_cause.message).to eq("Archive file #{archive_file_path} could not be unpacked. Tar archive looks corrupt.")
        end
      end

      context "when the archive is a gzip file of a very malformed tar archive" do

        before do
          Zlib::GzipWriter.open(archive_file_path) do |gz_file|
            gz_file << "\0\0\0\0\0"
          end
        end

        it "errors out" do
          expect(exception).to_not be_nil
          expect(exception.message).to eq("Failed to publish archived policy")
          expect(exception_cause).to be_a(ChefDK::InvalidPolicyArchive)
          expect(exception_cause.message).to eq("Archive file #{archive_file_path} could not be unpacked. Tar archive looks corrupt.")
        end
      end
    end

    context "when the archive is well-formed but has invalid content" do

      before do
        create_archive
      end

      context "when the archive is missing Policyfile.lock.json" do

        let(:archive_files) { [ FileToTar.new("empty.txt", "") ] }

        it "errors out" do
          expect(exception).to_not be_nil
          expect(exception.message).to eq("Failed to publish archived policy")
          expect(exception_cause).to be_a(ChefDK::InvalidPolicyArchive)
          expect(exception_cause.message).to eq("Archive does not contain a Policyfile.lock.json")
        end

      end

      context "when the archive has no cookbook_artifacts/ directory" do

        let(:archive_files) { [ FileToTar.new("Policyfile.lock.json", "") ] }

        it "errors out" do
          expect(exception).to_not be_nil
          expect(exception.message).to eq("Failed to publish archived policy")
          expect(exception_cause).to be_a(ChefDK::InvalidPolicyArchive)
          expect(exception_cause.message).to eq("Archive does not contain a cookbook_artifacts directory")
        end

      end

      context "when the archive has the correct files but the lockfile is invalid" do

        let(:archive_dirs) { ["cookbook_artifacts"] }

        let(:archive_files) { [ FileToTar.new("Policyfile.lock.json", lockfile_content) ] }

        context "when the lockfile has invalid JSON" do

          let(:lockfile_content) { ":::" }

          it "errors out" do
            expect(exception).to_not be_nil
            expect(exception.message).to eq("Failed to publish archived policy")
            expect(exception_cause).to be_a(FFI_Yajl::ParseError)
          end

        end

        context "when the lockfile is semantically invalid" do

          let(:lockfile_content) { "{ }" }

          it "errors out" do
            expect(exception).to_not be_nil
            expect(exception.message).to eq("Failed to publish archived policy")
            expect(exception_cause).to be_a(ChefDK::InvalidLockfile)
          end

        end

        context "when the archive does not have all the necessary cookbooks" do

          let(:lockfile_content) { valid_lockfile }

          it "errors out" do
            expect(exception).to_not be_nil
            expect(exception.message).to eq("Failed to publish archived policy")
            expect(exception_cause).to be_a(ChefDK::InvalidPolicyArchive)

            msg = "Archive does not have all cookbooks required by the Policyfile.lock. Missing cookbooks: 'local-cookbook'."
            expect(exception_cause.message).to eq(msg)
          end

        end

        # `chef export` previously generated Chef repos designed for
        # compatibility mode Policyfile usage. We don't intend to be backwards
        # compatible, but we want to kindly explain what's going on.
        context "when the archive is in the old format" do

          let(:lockfile_content) { valid_lockfile }

          let(:archive_dirs) { %w{ cookbooks data_bags } }

          let(:archive_files) do
            [
              FileToTar.new("Policyfile.lock.json", lockfile_content),
              FileToTar.new("client.rb", "#content"),
            ]
          end

          it "errors out, explaining the compatibility issue" do
            expect(exception).to_not be_nil
            expect(exception.message).to eq("Failed to publish archived policy")
            expect(exception_cause).to be_a(ChefDK::InvalidPolicyArchive)

            msg = <<-MESSAGE
This archive is in an unsupported format.

This archive was created with an older version of ChefDK. This version of
ChefDK does not support archives in the older format. Re-create the archive
with a newer version of ChefDK or downgrade ChefDK.
MESSAGE
            expect(exception_cause.message).to eq(msg)
          end

        end
      end
    end

  end

  context "with a valid archive" do

    let(:lockfile_content) { valid_lockfile }

    let(:cookbook_name) { "local-cookbook" }

    let(:identifier) { "fab501cfaf747901bd82c1bc706beae7dc3a350c" }

    let(:cookbook_artifact_dir) { File.join("cookbook_artifacts", "#{cookbook_name}-#{identifier}") }

    let(:recipes_dir) { File.join(cookbook_artifact_dir, "recipes") }

    let(:archive_dirs) { ["cookbook_artifacts", cookbook_artifact_dir, recipes_dir] }

    let(:archive_files) do
      [
        FileToTar.new("Policyfile.lock.json", lockfile_content),
        FileToTar.new(File.join(cookbook_artifact_dir, "metadata.rb"), "name 'local-cookbook'"),
        FileToTar.new(File.join(recipes_dir, "default.rb"), "puts 'hello'"),
      ]
    end

    let(:http_client) { instance_double(Chef::ServerAPI) }

    let(:uploader) { instance_double(ChefDK::Policyfile::Uploader) }

    before do
      expect(push_archive_service).to receive(:http_client).and_return(http_client)

      expect(ChefDK::Policyfile::Uploader).to receive(:new).
        # TODO: need more verification that the policyfile.lock is right (?)
        with(an_instance_of(ChefDK::PolicyfileLock), policy_group, http_client: http_client, ui: ui, policy_document_native_api: true).
        and_return(uploader)

      create_archive
    end

    describe "when the upload is successful" do

      it "uploads the cookbooks and lockfile" do
        expect(uploader).to receive(:upload)
        push_archive_service.run
      end

    end

    describe "when the upload fails" do

      it "raises a nested error" do
        expect(uploader).to receive(:upload).and_raise("an error")
        expect { push_archive_service.run }.to raise_error(ChefDK::PolicyfilePushArchiveError)
      end

    end

  end

end
