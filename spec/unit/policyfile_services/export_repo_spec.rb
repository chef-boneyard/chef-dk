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

  subject(:export_service) { described_class.new(policyfile: policyfile_rb_explicit_name,
                                                 root_dir: working_dir,
                                                 export_dir: export_dir) }

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

      describe "writing updates to the policyfile lock" do

        let(:updated_lockfile_io) { StringIO.new }

        it "validates the lockfile and writes updates to disk" do
          allow(File).to receive(:open).and_call_original
          expect(File).to receive(:open).with(policyfile_lock_path, "wb+").and_yield(updated_lockfile_io)

          export_service.run
        end

      end

      context "copying the cookbooks to the export dir" do

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

      end
    end

  end



end

