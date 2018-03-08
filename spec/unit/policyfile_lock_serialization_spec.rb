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
require "chef-dk/policyfile_lock"

describe ChefDK::PolicyfileLock, "when reading a Policyfile.lock" do

  let(:valid_lock_data) do
    {
      "name" => "example",
      "run_list" => [ "recipe[cookbook::recipe_name]" ],
      "named_run_lists" => {
        "fast-deploy" => [ "recipe[cookbook::deployit]" ],
      },
      "cookbook_locks" => {
        # TODO: add some valid locks
      },
      "default_attributes" => { "foo" => "bar" },
      "override_attributes" => { "override_foo" => "override_bar" },
      "solution_dependencies" => {
        "Policyfile" => [],
        "dependencies" => {},
      },
    }
  end

  let(:storage_config) { ChefDK::Policyfile::StorageConfig.new }

  let(:lockfile) { ChefDK::PolicyfileLock.new(storage_config) }

  describe "populating the deserialized lock" do

    before do
      lockfile.build_from_lock_data(valid_lock_data)
    end

    it "includes the run list" do
      expect(lockfile.run_list).to eq(["recipe[cookbook::recipe_name]"])
    end

    it "includes the named run lists" do
      expect(lockfile.named_run_lists).to eq({ "fast-deploy" => [ "recipe[cookbook::deployit]" ] })
    end

    it "includes the cookbook locks" do
      expect(lockfile.cookbook_locks).to eq({})
    end

    it "includes the attributes" do
      expect(lockfile.default_attributes).to eq({ "foo" => "bar" })
      expect(lockfile.override_attributes).to eq({ "override_foo" => "override_bar" })
    end

  end

  describe "validating required fields" do

    it "does not raise an error when all fields are valid" do
      expect { lockfile.build_from_lock_data(valid_lock_data) }.to_not raise_error
    end

    it "requires the name to be present" do
      missing_name = valid_lock_data.dup
      missing_name.delete("name")

      expect { lockfile.build_from_lock_data(missing_name) }.to raise_error(ChefDK::InvalidLockfile)

      blank_name = valid_lock_data.dup
      blank_name["name"] = ""
      expect { lockfile.build_from_lock_data(blank_name) }.to raise_error(ChefDK::InvalidLockfile)

      invalid_name = valid_lock_data.dup
      invalid_name["name"] = {}
      expect { lockfile.build_from_lock_data(invalid_name) }.to raise_error(ChefDK::InvalidLockfile)
    end

    it "requires the run_list to be present" do
      no_run_list = valid_lock_data.dup
      no_run_list.delete("run_list")

      expect { lockfile.build_from_lock_data(no_run_list) }.to raise_error(ChefDK::InvalidLockfile)

      bad_run_list = valid_lock_data.dup
      bad_run_list["run_list"] = "bad data"
      expect { lockfile.build_from_lock_data(bad_run_list) }.to raise_error(ChefDK::InvalidLockfile)
    end

    it "validates the format of run_list items" do
      bad_run_list = valid_lock_data.dup
      bad_run_list["run_list"] = [ "bad data" ]

      expect { lockfile.build_from_lock_data(bad_run_list) }.to raise_error(ChefDK::InvalidLockfile)
    end

    it "allows the named_run_lists field to be absent" do
      missing_named_run_lists = valid_lock_data.dup
      missing_named_run_lists.delete("named_run_lists")

      expect { lockfile.build_from_lock_data(missing_named_run_lists) }.to_not raise_error
    end

    it "requires the named_run_lists field to be a Hash if present" do
      bad_named_run_lists = valid_lock_data.dup
      bad_named_run_lists["named_run_lists"] = false

      expect { lockfile.build_from_lock_data(bad_named_run_lists) }.to raise_error(ChefDK::InvalidLockfile)
    end

    it "requires the keys in named_run_lists to be strings" do
      bad_named_run_lists = valid_lock_data.dup
      bad_named_run_lists["named_run_lists"] = { 42 => [] }

      expect { lockfile.build_from_lock_data(bad_named_run_lists) }.to raise_error(ChefDK::InvalidLockfile)
    end

    it "requires the values in named_run_lists to be arrays" do
      bad_named_run_lists = valid_lock_data.dup
      bad_named_run_lists["named_run_lists"] = { "bad" => 42 }

      expect { lockfile.build_from_lock_data(bad_named_run_lists) }.to raise_error(ChefDK::InvalidLockfile)
    end

    it "requires the values in named_run_lists to be valid run lists" do
      bad_named_run_lists = valid_lock_data.dup
      bad_named_run_lists["named_run_lists"] = { "bad" => [ 42 ] }

      expect { lockfile.build_from_lock_data(bad_named_run_lists) }.to raise_error(ChefDK::InvalidLockfile)
    end
    it "requires the `cookbook_locks` section be present and its value is a Hash" do
      missing_locks = valid_lock_data.dup
      missing_locks.delete("cookbook_locks")

      expect { lockfile.build_from_lock_data(missing_locks) }.to raise_error(ChefDK::InvalidLockfile)

      invalid_locks = valid_lock_data.dup
      invalid_locks["cookbook_locks"] = []
      expect { lockfile.build_from_lock_data(invalid_locks) }.to raise_error(ChefDK::InvalidLockfile)
    end

    it "requires the `default_attributes` section be present and its value is a Hash" do
      missing_attrs = valid_lock_data.dup
      missing_attrs.delete("default_attributes")

      expect { lockfile.build_from_lock_data(missing_attrs) }.to raise_error(ChefDK::InvalidLockfile)

      invalid_attrs = valid_lock_data.dup
      invalid_attrs["default_attributes"] = []

      expect { lockfile.build_from_lock_data(invalid_attrs) }.to raise_error(ChefDK::InvalidLockfile)
    end

    it "requires the `override_attributes` section be present and its value is a Hash" do
      missing_attrs = valid_lock_data.dup
      missing_attrs.delete("override_attributes")

      expect { lockfile.build_from_lock_data(missing_attrs) }.to raise_error(ChefDK::InvalidLockfile)

      invalid_attrs = valid_lock_data.dup
      invalid_attrs["override_attributes"] = []

      expect { lockfile.build_from_lock_data(invalid_attrs) }.to raise_error(ChefDK::InvalidLockfile)
    end

    describe "validating solution_dependencies" do

      it "requires the `solution_dependencies' section be present" do
        missing_soln_deps = valid_lock_data.dup
        missing_soln_deps.delete("solution_dependencies")

        expect { lockfile.build_from_lock_data(missing_soln_deps) }.to raise_error(ChefDK::InvalidLockfile)
      end

      it "requires the solution_dependencies object be a Hash" do
        invalid_soln_deps = valid_lock_data.dup
        invalid_soln_deps["solution_dependencies"] = []
        expect { lockfile.build_from_lock_data(invalid_soln_deps) }.to raise_error(ChefDK::InvalidLockfile)
      end

      it "requires the solution_dependencies object have a 'Policyfile' and 'dependencies' key" do
        missing_keys_soln_deps = valid_lock_data.dup
        missing_keys_soln_deps["solution_dependencies"] = {}
        expect { lockfile.build_from_lock_data(missing_keys_soln_deps) }.to raise_error(ChefDK::InvalidLockfile)

        missing_policyfile_key = valid_lock_data.dup
        missing_policyfile_key["solution_dependencies"] = { "dependencies" => {} }
        expect { lockfile.build_from_lock_data(missing_policyfile_key) }.to raise_error(ChefDK::InvalidLockfile)

        missing_dependencies_key = valid_lock_data.dup
        missing_dependencies_key["solution_dependencies"] = { "Policyfile" => [] }
        expect { lockfile.build_from_lock_data(missing_dependencies_key) }.to raise_error(ChefDK::InvalidLockfile)
      end

      it "requires the Policyfile dependencies be an Array" do
        invalid_policyfile_deps = valid_lock_data.dup
        invalid_policyfile_deps["solution_dependencies"] = { "Policyfile" => 42, "dependencies" => {} }
        expect { lockfile.build_from_lock_data(invalid_policyfile_deps) }.to raise_error(ChefDK::InvalidLockfile)
      end

      it %q{requires the Policyfile dependencies be formatted like [ "COOKBOOK_NAME", "CONSTRAINT" ]} do
        invalid_policyfile_deps_content = valid_lock_data.dup
        invalid_policyfile_deps_content["solution_dependencies"] = { "Policyfile" => [ "bad" ], "dependencies" => {} }
        expect { lockfile.build_from_lock_data(invalid_policyfile_deps_content) }.to raise_error(ChefDK::InvalidLockfile)

        invalid_policyfile_deps_content2 = valid_lock_data.dup
        invalid_policyfile_deps_content2["solution_dependencies"] = { "Policyfile" => [ [42, "~> 2.0"] ], "dependencies" => {} }
        expect { lockfile.build_from_lock_data(invalid_policyfile_deps_content2) }.to raise_error(ChefDK::InvalidLockfile)

        invalid_policyfile_deps_content3 = valid_lock_data.dup
        invalid_policyfile_deps_content3["solution_dependencies"] = { "Policyfile" => [ %w{cookbook_name bad} ], "dependencies" => {} }
        expect { lockfile.build_from_lock_data(invalid_policyfile_deps_content3) }.to raise_error(ChefDK::InvalidLockfile)
      end

      it "requires the cookbook dependencies be a Hash" do
        invalid_cookbook_deps = valid_lock_data.dup
        invalid_cookbook_deps["solution_dependencies"] = { "Policyfile" => [], "dependencies" => 42 }
        expect { lockfile.build_from_lock_data(invalid_cookbook_deps) }.to raise_error(ChefDK::InvalidLockfile)
      end

      it "requires the cookbook dependencies entries be in the correct format" do
        invalid_cookbook_deps = valid_lock_data.dup
        bad_deps = { 42 => 42 }
        invalid_cookbook_deps["solution_dependencies"] = { "Policyfile" => [], "dependencies" => bad_deps }
        expect { lockfile.build_from_lock_data(invalid_cookbook_deps) }.to raise_error(ChefDK::InvalidLockfile)

        invalid_cookbook_deps2 = valid_lock_data.dup
        bad_deps2 = { "bad-format" => [] }
        invalid_cookbook_deps2["solution_dependencies"] = { "Policyfile" => [], "dependencies" => bad_deps2 }
        expect { lockfile.build_from_lock_data(invalid_cookbook_deps2) }.to raise_error(ChefDK::InvalidLockfile)

        invalid_cookbook_deps3 = valid_lock_data.dup
        bad_deps3 = { "cookbook (1.0.0)" => 42 }
        invalid_cookbook_deps3["solution_dependencies"] = { "Policyfile" => [], "dependencies" => bad_deps3 }
        expect { lockfile.build_from_lock_data(invalid_cookbook_deps3) }.to raise_error(ChefDK::InvalidLockfile)

        invalid_cookbook_deps4 = valid_lock_data.dup
        bad_deps4 = { "cookbook (1.0.0)" => [ 42 ] }
        invalid_cookbook_deps4["solution_dependencies"] = { "Policyfile" => [], "dependencies" => bad_deps4 }
        expect { lockfile.build_from_lock_data(invalid_cookbook_deps4) }.to raise_error(ChefDK::InvalidLockfile)
      end
    end

    describe "validating cookbook_locks entries" do

      # TODO: also check non-cached cookbook
      let(:valid_cookbook_lock) do
        {
          "version" => "1.0.0",
          "identifier" => "68c13b136a49b4e66cfe9d8aa2b5a85167b5bf9b",
          "dotted_decimal_identifier" => "111.222.333",
          "cache_key" => "foo-1.0.0",
          "source_options" => {},
        }
      end

      it "requires that each cookbook lock be a Hash" do
        invalid_cookbook_lock = valid_lock_data.dup
        invalid_cookbook_lock["cookbook_locks"] = { "foo" => 42 }
        expect { lockfile.build_from_lock_data(invalid_cookbook_lock) }.to raise_error(ChefDK::InvalidLockfile)
      end

      it "requires that cookbook locks not be empty" do
        invalid_cookbook_lock = valid_lock_data.dup
        invalid_cookbook_lock["cookbook_locks"] = { "foo" => {} }
        expect { lockfile.build_from_lock_data(invalid_cookbook_lock) }.to raise_error(ChefDK::InvalidLockfile)
      end

      it "requires that each cookbook lock have a version" do
        invalid_lockfile = valid_lock_data.dup
        invalid_cookbook_lock = valid_cookbook_lock.dup
        invalid_cookbook_lock.delete("version")
        invalid_lockfile["cookbook_locks"] = { "foo" => invalid_cookbook_lock }
        expect { lockfile.build_from_lock_data(invalid_lockfile) }.to raise_error(ChefDK::InvalidLockfile)
      end

      it "requires that the version be a string" do
        invalid_lockfile = valid_lock_data.dup
        invalid_cookbook_lock = valid_cookbook_lock.dup
        invalid_cookbook_lock["version"] = 42
        invalid_lockfile["cookbook_locks"] = { "foo" => invalid_cookbook_lock }
        expect { lockfile.build_from_lock_data(invalid_lockfile) }.to raise_error(ChefDK::InvalidLockfile)
      end

      it "requires that each cookbook lock have an identifier" do
        invalid_lockfile = valid_lock_data.dup
        invalid_cookbook_lock = valid_cookbook_lock.dup
        invalid_cookbook_lock.delete("identifier")
        invalid_lockfile["cookbook_locks"] = { "foo" => invalid_cookbook_lock }
        expect { lockfile.build_from_lock_data(invalid_lockfile) }.to raise_error(ChefDK::InvalidLockfile)
      end

      it "requires that the identifier be a string" do
        invalid_lockfile = valid_lock_data.dup
        invalid_cookbook_lock = valid_cookbook_lock.dup
        invalid_cookbook_lock["identifier"] = 42
        invalid_lockfile["cookbook_locks"] = { "foo" => invalid_cookbook_lock }
        expect { lockfile.build_from_lock_data(invalid_lockfile) }.to raise_error(ChefDK::InvalidLockfile)
      end

      it "requires that a cookbook lock have a key named `cache_key'" do
        invalid_lockfile = valid_lock_data.dup
        invalid_cookbook_lock = valid_cookbook_lock.dup
        invalid_cookbook_lock.delete("cache_key")
        invalid_lockfile["cookbook_locks"] = { "foo" => invalid_cookbook_lock }
        expect { lockfile.build_from_lock_data(invalid_lockfile) }.to raise_error(ChefDK::InvalidLockfile)
      end

      it "requires that the cache_key be a string or null" do
        invalid_lockfile = valid_lock_data.dup
        invalid_cookbook_lock = valid_cookbook_lock.dup
        invalid_cookbook_lock["cache_key"] = 42
        invalid_lockfile["cookbook_locks"] = { "foo" => invalid_cookbook_lock }
        expect { lockfile.build_from_lock_data(invalid_lockfile) }.to raise_error(ChefDK::InvalidLockfile)
      end

      it "requires that a cookbook lock have a source_options attribute" do
        invalid_lockfile = valid_lock_data.dup
        invalid_cookbook_lock = valid_cookbook_lock.dup
        invalid_cookbook_lock.delete("source_options")
        invalid_lockfile["cookbook_locks"] = { "foo" => invalid_cookbook_lock }
        expect { lockfile.build_from_lock_data(invalid_lockfile) }.to raise_error(ChefDK::InvalidLockfile)
      end

      it "requires that source options be a Hash" do
        invalid_lockfile = valid_lock_data.dup
        invalid_cookbook_lock = valid_cookbook_lock.dup
        invalid_cookbook_lock["source_options"] = 42
        invalid_lockfile["cookbook_locks"] = { "foo" => invalid_cookbook_lock }
        expect { lockfile.build_from_lock_data(invalid_lockfile) }.to raise_error(ChefDK::InvalidLockfile)
      end

      it "requires that a cookbook lock be a valid local cookbook if `cache_key' is null/nil" do
        valid_lock_with_local_cookbook = valid_lock_data.dup
        valid_local_cookbook = valid_cookbook_lock.dup
        valid_local_cookbook["cache_key"] = nil
        valid_local_cookbook["source"] = "path/to/foo"
        valid_lock_with_local_cookbook["cookbook_locks"] = { "foo" => valid_local_cookbook }
        expect { lockfile.build_from_lock_data(valid_lock_with_local_cookbook) }.to_not raise_error

        invalid_lock_with_local_cookbook = valid_lock_data.dup
        invalid_local_cookbook = valid_cookbook_lock.dup
        invalid_local_cookbook["cache_key"] = nil
        invalid_local_cookbook["source"] = 42
        invalid_lock_with_local_cookbook["cookbook_locks"] = { "foo" => invalid_local_cookbook }
        expect { lockfile.build_from_lock_data(invalid_lock_with_local_cookbook) }.to raise_error(ChefDK::InvalidLockfile)
      end

      it "requires that a cookbook lock w/ a key named `cache_key' be a valid cached cookbook structure" do
        valid_lock_with_cached_cookbook = valid_lock_data.dup
        valid_cached_cookbook = valid_cookbook_lock.dup
        valid_cached_cookbook["cache_key"] = nil
        valid_cached_cookbook["source"] = "path/to/foo"
        valid_lock_with_cached_cookbook["cookbook_locks"] = { "foo" => valid_cached_cookbook }
        expect { lockfile.build_from_lock_data(valid_lock_with_cached_cookbook) }.to_not raise_error

        invalid_lock_with_cached_cookbook = valid_lock_data.dup
        invalid_cached_cookbook = valid_cookbook_lock.dup
        invalid_cached_cookbook["cache_key"] = 42
        invalid_lock_with_cached_cookbook["cookbook_locks"] = { "foo" => invalid_cached_cookbook }
        expect { lockfile.build_from_lock_data(invalid_lock_with_cached_cookbook) }.to raise_error(ChefDK::InvalidLockfile)
      end

    end
  end

  describe "populating lock data from an archive" do

    let(:valid_cookbook_lock) do
      {
        "version" => "1.0.0",
        "identifier" => "68c13b136a49b4e66cfe9d8aa2b5a85167b5bf9b",
        "dotted_decimal_identifier" => "111.222.333",
        "cache_key" => nil,
        "source" => "path/to/foo",
        "source_options" => { path: "path/to/foo" },
        "scm_info" => nil,
      }
    end

    let(:lock_data) do
      valid_lock_with_cached_cookbook = valid_lock_data.dup
      valid_cached_cookbook = valid_cookbook_lock.dup
      valid_cached_cookbook["cache_key"] = nil
      valid_cached_cookbook["source"] = "path/to/foo"
      valid_lock_with_cached_cookbook["cookbook_locks"] = { "foo" => valid_cached_cookbook }
      valid_lock_with_cached_cookbook
    end

    before do
      lockfile.build_from_archive(lock_data)
    end

    it "creates cookbook locks as archived cookbooks" do
      locks = lockfile.cookbook_locks

      expect(locks).to have_key("foo")

      cb_foo = locks["foo"]
      expect(cb_foo).to be_a(ChefDK::Policyfile::ArchivedCookbook)

      expected_path = File.join(storage_config.relative_paths_root, "cookbook_artifacts", "foo-68c13b136a49b4e66cfe9d8aa2b5a85167b5bf9b")

      expect(cb_foo.cookbook_path).to eq(expected_path)
      expect(cb_foo.dotted_decimal_identifier).to eq("111.222.333")
      expect(locks["foo"].to_lock).to eq(valid_cookbook_lock)
    end

  end

end
