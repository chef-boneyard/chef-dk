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
require "chef-dk/helpers"
require "chef-dk/policyfile_services/update_attributes"

describe ChefDK::PolicyfileServices::UpdateAttributes do

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

  let(:local_cookbooks_root) do
    File.join(fixtures_path, "local_path_cookbooks")
  end

  let(:local_cookbook_path) { File.join(local_cookbooks_root, "local-cookbook") }

  let(:local_cookbook_copy_path) { File.join(working_dir, "cookbooks/local-cookbook") }

  let(:policyfile_content) do
    <<~E
      name 'install-example'

      run_list 'local-cookbook'

      cookbook 'local-cookbook', path: 'cookbooks/local-cookbook'

      default["default_attr"] = "new_value_default"

      override["override_attr"] = "new_value_override"
    E
  end

  let(:ui) { TestHelpers::TestUI.new }

  let(:storage_config) do
    ChefDK::Policyfile::StorageConfig.new( cache_path: nil, relative_paths_root: working_dir )
  end

  subject(:update_attrs_service) { described_class.new(policyfile: policyfile_rb_name, ui: ui, root_dir: working_dir) }

  before do
    FileUtils.mkdir_p(File.dirname(local_cookbook_copy_path))
    FileUtils.cp_r(local_cookbook_path, local_cookbook_copy_path)
  end

  context "when first created" do

    it "has the UI object it was created with" do
      expect(update_attrs_service.ui).to eq(ui)
    end

    it "creates a storage config from the given policyfile path and root dir" do
      new_storage_config = instance_double("ChefDK::Policyfile::StorageConfig")
      expect(ChefDK::Policyfile::StorageConfig).to receive(:new).with(no_args).and_return(new_storage_config)
      expect(new_storage_config).to receive(:use_policyfile).with(policyfile_rb_path).and_return(new_storage_config)
      expect(update_attrs_service.storage_config).to eq(new_storage_config)
    end

  end

  context "when no Policyfile is present or specified" do

    it "errors out" do
      expect { update_attrs_service.assert_policy_and_lock_present! }.to raise_error(ChefDK::PolicyfileNotFound, "Policyfile not found at path #{policyfile_rb_path}")
      expect { update_attrs_service.run }.to raise_error(ChefDK::PolicyfileUpdateError)
    end

  end

  context "when no lockfile exists" do

    it "errors out" do
      with_file(policyfile_rb_path) { |f| f.print(policyfile_content) }
      expect { update_attrs_service.assert_policy_and_lock_present! }.to raise_error(ChefDK::LockfileNotFound, "Policyfile lock not found at path #{policyfile_lock_path}")
      expect { update_attrs_service.run }.to raise_error(ChefDK::PolicyfileUpdateError)
    end

  end

  context "when both the policyfile and lockfile exist" do

    let(:lock_data_with_new_values) do
      {
        "revision_id" => "522d740beba4c4e5857bd8bccdb2d7ffd0bbd45ac4350f92b26e4e3b8f68d530",
        "name" => "install-example",
        "run_list" => ["recipe[local-cookbook::default]"],
        "cookbook_locks" => {
          "local-cookbook" => {
            "version" => "2.3.4",
            "identifier" => "fab501cfaf747901bd82c1bc706beae7dc3a350c",
            "dotted_decimal_identifier" => "70567763561641081.489844270461035.258281553147148",
            "source" => "cookbooks/local-cookbook",
            "cache_key" => nil,
            "scm_info" => nil,
            "source_options" => {
              "path" => "cookbooks/local-cookbook",
            },
          },
        },
        "default_attributes" => { "default_attr" => "new_value_default" },
        "override_attributes" => { "override_attr" => "new_value_override" },
        "solution_dependencies" => {
          "Policyfile" => [["local-cookbook", ">= 0.0.0"]],
          "dependencies" => { "local-cookbook (2.3.4)" => [] },
        },
        "included_policy_locks" => [],
      }
    end

    let(:previous_policyfile_lock_data) { lock_data_with_new_values }

    let(:policyfile_lock_content) do
      FFI_Yajl::Encoder.encode(previous_policyfile_lock_data, pretty: true )
    end

    before do
      with_file(policyfile_rb_path) { |f| f.print(policyfile_content) }
      with_file(policyfile_lock_path) { |f| f.print(policyfile_lock_content) }
    end

    def result_policyfile_lock_data
      expect(File).to exist(policyfile_lock_path)
      content = IO.read(policyfile_lock_path)
      FFI_Yajl::Parser.parse(content)
    end

    context "when the current lock already has the desired attributes" do

      it "makes no changes to the lockfile" do
        update_attrs_service.run
        expect(result_policyfile_lock_data).to eq(lock_data_with_new_values)
      end

      it "emits a message that no changes have been made to the lockfile" do
        update_attrs_service.run

        message = "Attributes already up to date"
        expect(ui.output).to include(message)
      end

      context "when a policyfile is included" do
        let(:lock_applier) { instance_double("ChefDK::Policyfile::LockApplier") }

        it "locks the included policyfile" do
          expect(ChefDK::Policyfile::LockApplier).to receive(:new).with(
            update_attrs_service.policyfile_lock, update_attrs_service.policyfile_compiler).and_return(lock_applier)
          expect(lock_applier).not_to receive(:with_unlocked_policies)
          expect(lock_applier).to receive(:apply!)

          update_attrs_service.run
        end
      end
    end

    context "when the Policyfile.rb has different attributes than the lockfile" do

      let(:previous_policyfile_lock_data) do
        {
          "revision_id" => "522d740beba4c4e5857bd8bccdb2d7ffd0bbd45ac4350f92b26e4e3b8f68d530",
          "name" => "install-example",
          "run_list" => ["recipe[local-cookbook::default]"],
          "cookbook_locks" => {
            "local-cookbook" => {
              "version" => "2.3.4",
              "identifier" => "fab501cfaf747901bd82c1bc706beae7dc3a350c",
              "dotted_decimal_identifier" => "70567763561641081.489844270461035.258281553147148",
              "source" => "cookbooks/local-cookbook",
              "cache_key" => nil,
              "scm_info" => nil,
              "source_options" => {
                "path" => "cookbooks/local-cookbook",
              },
            },
          },
          "default_attributes" => { "default_attr" => "old_value_default" },
          "override_attributes" => { "override_attr" => "old_value_override" },
          "solution_dependencies" => {
            "Policyfile" => [["local-cookbook", ">= 0.0.0"]],
            "dependencies" => { "local-cookbook (2.3.4)" => [] },
          },
        }
      end

      it "updates the lockfile with the new attributes" do
        update_attrs_service.run
        expect(result_policyfile_lock_data).to eq(lock_data_with_new_values)
      end

      it "emits a messsage stating the attributes have been updated" do
        update_attrs_service.run
        expect(ui.output).to include("Updated attributes in #{policyfile_lock_path}")
      end

    end

  end

end
