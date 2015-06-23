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
require 'chef-dk/policyfile_services/export_repo'

describe ChefDK::PolicyfileServices::ExportRepo do

  let(:working_dir) do
    path = File.join(tempdir, "policyfile_services_test_working_dir")
    Dir.mkdir(path)
    path
  end

  let(:export_dir) { File.join(tempdir, "export_repo_export_dir") }

  let(:policyfile_rb_explicit_name) { nil }

  let(:policyfile_rb_name) { policyfile_rb_explicit_name || "Policyfile.rb" }

  let(:expanded_policyfile_path) { File.join(working_dir, policyfile_rb_name) }

  let(:policyfile_lock_name) { "Policyfile.lock.json" }

  let(:policyfile_lock_path) { File.join(working_dir, policyfile_lock_name) }

  let(:force_export) { false }

  let(:archive) { false }

  subject(:export_service) do
    described_class.new(policyfile: policyfile_rb_explicit_name,
                        root_dir: working_dir,
                        export_dir: export_dir,
                        archive: archive,
                        force: force_export)
  end

  it "uses Policyfile.rb as the default Policyfile name" do
    expect(export_service.policyfile_filename).to eq(expanded_policyfile_path)
  end

  context "when given an explicit Policyfile name" do

    let(:policyfile_rb_explicit_name) { "MyPolicy.rb" }

    it "uses the given Policyfile name" do
      expect(export_service.policyfile_filename).to eq(expanded_policyfile_path)
    end

  end

  it "has a destination directory for the export" do
    expect(export_service.export_dir).to eq(export_dir)
  end

  context "when the policyfile lock is missing" do

    it "raises an error that suggests you run `chef install'" do
      expect { export_service.run }.to raise_error(ChefDK::LockfileNotFound)
    end

  end

  context "when a lockfile is present" do

    before do
      File.open(policyfile_lock_path, "w+") { |f| f.print(lockfile_content) }
    end

    context "and the lockfile has invalid JSON" do

      let(:lockfile_content) { ":::" }

      it "errors out" do
        expect { export_service.run }.to raise_error(ChefDK::PolicyfileExportRepoError, /Error reading lockfile/)
      end

    end

    context "and the lockfile is semantically invalid" do

      let(:lockfile_content) { '{ }' }

      it "errors out" do
        expect { export_service.run }.to raise_error(ChefDK::PolicyfileExportRepoError, /Invalid lockfile data/)
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

      it "reads the lockfile data" do
        lock = export_service.policyfile_lock
        expect(lock).to be_an_instance_of(ChefDK::PolicyfileLock)
        expect(lock.name).to eq("install-example")
        expect(lock.cookbook_locks.size).to eq(1)
        expect(lock.cookbook_locks).to have_key("local-cookbook")
      end

      it "delegates #policy_name to the lockfile" do
        expect(export_service.policy_name).to eq("install-example")
      end

      context "when using archive mode" do

        let(:archive) { true }

        # TODO: also support a full file name
        context "when the given 'export_dir' is a directory" do

          it "sets the archive file location to $policy_name-$revision.tgz" do
            expected = File.join(export_dir, "install-example-60e5ad638dce219d8f87d589463ec4a9884007ba5e2adbb4c0a7021d67204f1a.tgz")
            expect(export_service.archive_file_location).to eq(expected)
          end

        end

      end

      describe "writing updates to the policyfile lock" do

        let(:updated_lockfile_io) { StringIO.new }

        it "validates the lockfile and writes updates to disk" do
          allow(File).to receive(:open).and_call_original
          expect(File).to receive(:open).with(policyfile_lock_path, "wb+").and_yield(updated_lockfile_io)

          export_service.run
        end

      end

      context "copying the cookbooks to the export dir" do

        shared_examples_for "successful_export" do
          before do
            allow(export_service.policyfile_lock).to receive(:validate_cookbooks!).and_return(true)
            export_service.run
          end

          let(:cookbook_files) do
            base_pathname = Pathname.new(local_cookbook_path)
            Dir.glob("#{local_cookbook_path}/**/*").map do |full_path|
              Pathname.new(full_path).relative_path_from(base_pathname)
            end
          end

          let(:expected_files_relative) do
            metadata_rb = Pathname.new("metadata.rb")
            expected = cookbook_files.delete_if { |p| p == metadata_rb }
            expected << Pathname.new("metadata.json")
          end

          let(:cookbook_with_version) { "local-cookbook-70567763561641081.489844270461035.258281553147148" }

          let(:exported_cookbook_root) { Pathname.new(File.join(export_dir, "cookbooks", cookbook_with_version)) }

          let(:expected_files) do
            expected_files_relative.map do |file_rel_path|
              exported_cookbook_root + file_rel_path
            end
          end

          it "copies cookbooks to the target dir in versioned_cookbooks format" do
            expected_files.each do |expected_file|
              expect(expected_file).to exist
            end
          end

          # This behavior does two things:
          # * ensures that Chef Zero uses our hacked version number
          # * works around external dependencies (e.g., using `git` in backticks)
          #   in metadata.rb issue
          it "writes metadata.json in the exported cookbook, removing metadata.rb" do
            metadata_json_path = File.join(exported_cookbook_root, "metadata.json")
            metadata_json = FFI_Yajl::Parser.parse(IO.read(metadata_json_path))
            expect(metadata_json["version"]).to eq("70567763561641081.489844270461035.258281553147148")
          end

          it "copies the policyfile lock in data item format to data_bags/policyfiles" do
            data_bag_item_path = File.join(export_dir, "data_bags", "policyfiles", "install-example-local.json")
            data_item_json = FFI_Yajl::Parser.parse(IO.read(data_bag_item_path))
            expect(data_item_json["id"]).to eq("install-example-local")
          end

        end

        context "when the export dir is empty" do

          include_examples "successful_export"
        end

        context "When an error occurs creating the export" do

          before do
            allow(export_service.policyfile_lock).to receive(:validate_cookbooks!).and_return(true)
            expect(export_service).to receive(:create_repo_structure).
              and_raise(Errno::EACCES.new("Permission denied @ rb_sysopen - /etc/foobarbaz.txt"))
          end

          it "wraps the error in a custom error class" do
            message = "Failed to export policy (in #{expanded_policyfile_path}) to #{export_dir}"
            expect { export_service.run }.to raise_error(ChefDK::PolicyfileExportRepoError, message)
          end

        end

        context "When the export dir has non-conflicting content" do

          let(:file_in_export_dir) { File.join(export_dir, "some_random_cruft") }

          let(:extra_data_bag_dir) { File.join(export_dir, "data_bags", "extraneous") }

          let(:extra_data_bag_item) { File.join(extra_data_bag_dir, "an_item.json") }

          before do
            FileUtils.mkdir_p(export_dir)
            File.open(file_in_export_dir, "wb+") { |f| f.print "some random cruft" }
            FileUtils.mkdir_p(extra_data_bag_dir)
            File.open(extra_data_bag_item, "wb+") { |f| f.print "some random cruft" }
          end

          it "ignores the non-conflicting content and exports" do
            expect(File).to exist(file_in_export_dir)
            expect(File).to exist(extra_data_bag_item)

            expect(File).to be_directory(File.join(export_dir, "cookbooks"))
            expect(File).to be_directory(File.join(export_dir, "data_bags"))
          end

          include_examples "successful_export"

        end

        context "When the export dir has conflicting content" do

          let(:non_conflicting_file_in_export_dir) { File.join(export_dir, "some_random_cruft") }

          let(:cookbooks_dir) { File.join(export_dir, "cookbooks") }

          let(:file_in_cookbooks_dir) { File.join(cookbooks_dir, "some_random_cruft") }

          let(:policyfiles_data_bag_dir) { File.join(export_dir, "data_bags", "policyfiles") }

          let(:extra_policyfile_data_item) { File.join(policyfiles_data_bag_dir, "leftover-policy.json") }

          before do
            FileUtils.mkdir_p(export_dir)
            FileUtils.mkdir_p(cookbooks_dir)
            FileUtils.mkdir_p(policyfiles_data_bag_dir)
            File.open(non_conflicting_file_in_export_dir, "wb+") { |f| f.print "some random cruft" }
            File.open(file_in_cookbooks_dir, "wb+") { |f| f.print "some random cruft" }
            File.open(extra_policyfile_data_item, "wb+") { |f| f.print "some random cruft" }
          end

          it "raises a PolicyfileExportRepoError" do
            message = "Export dir (#{export_dir}) not clean. Refusing to export. (Conflicting files: #{file_in_cookbooks_dir}, #{extra_policyfile_data_item})"
            expect { export_service.run }.to raise_error(ChefDK::ExportDirNotEmpty, message)
            expect(File).to exist(non_conflicting_file_in_export_dir)
            expect(File).to exist(file_in_cookbooks_dir)
            expect(File).to exist(extra_policyfile_data_item)
          end

          context "and the force option is set" do

            let(:force_export) { true }

            it "clears the export dir and exports" do
              export_service.run

              expect(File).to_not exist(file_in_cookbooks_dir)
              expect(File).to_not exist(extra_policyfile_data_item)

              expect(File).to exist(non_conflicting_file_in_export_dir)

              expect(File).to be_directory(File.join(export_dir, "cookbooks"))
              expect(File).to be_directory(File.join(export_dir, "data_bags"))
            end

          end

        end # When the export dir has conflicting content

        context "when archive mode is enabled" do

          let(:archive) { true }

          let(:expected_archive_path) do
            File.join(export_dir, "install-example-60e5ad638dce219d8f87d589463ec4a9884007ba5e2adbb4c0a7021d67204f1a.tgz")
          end

          it "exports the repo as a tgz archive" do
            expect(File).to exist(expected_archive_path)
          end

          include_examples "successful_export" do

            # explode the tarball so the assertions can find the files
            before do
              Zlib::GzipReader.open(expected_archive_path) do |gz_file|
                tar = Archive::Tar::Minitar::Input.new(gz_file)
                tar.each do |e|
                  tar.extract_entry(export_dir, e)
                end
              end
            end

          end

          context "when the target dir has a cookbooks or data_bags dir" do

            let(:cookbooks_dir) { File.join(export_dir, "cookbooks") }

            let(:file_in_cookbooks_dir) { File.join(cookbooks_dir, "some_random_cruft") }

            let(:policyfiles_data_bag_dir) { File.join(export_dir, "data_bags", "policyfiles") }

            let(:extra_policyfile_data_item) { File.join(policyfiles_data_bag_dir, "leftover-policy.json") }

            before do
              FileUtils.mkdir_p(export_dir)
              FileUtils.mkdir_p(cookbooks_dir)
              FileUtils.mkdir_p(policyfiles_data_bag_dir)
              File.open(file_in_cookbooks_dir, "wb+") { |f| f.print "some random cruft" }
              File.open(extra_policyfile_data_item, "wb+") { |f| f.print "some random cruft" }
            end

            it "exports successfully" do
              expect { export_service.run }.to_not raise_error
              expect(File).to exist(expected_archive_path)
            end

          end

        end # when archive mode is enabled

      end # copying the cookbooks to the export dir
    end

  end



end

