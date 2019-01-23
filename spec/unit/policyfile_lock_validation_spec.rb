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
require "chef-dk/policyfile_lock.rb"

describe ChefDK::PolicyfileLock, "validating locked cookbooks" do

  include ChefDK::Helpers

  let(:pristine_cache_path) do
    File.expand_path("spec/unit/fixtures/cookbook_cache", project_root)
  end

  let(:cache_path) do
    temp_cache_path = File.join(tempdir, "local_cache")
    FileUtils.cp_r(pristine_cache_path, temp_cache_path)
    temp_cache_path
  end

  let(:policyfile_lock_path) { "/fakepath/Policyfile.lock.json" }

  let(:local_cookbooks_root) do
    temp_local_path_cookbooks = File.join(tempdir, "local_path_cookbooks")
    FileUtils.cp_r(File.join(fixtures_path, "local_path_cookbooks"), temp_local_path_cookbooks)
    temp_local_path_cookbooks
  end

  let(:name) { "application-server" }

  let(:run_list) { [ "recipe[erlang::default]", "recipe[erchef::prereqs]", "recipe[erchef::app]" ] }

  let(:storage_config) do
    ChefDK::Policyfile::StorageConfig.new( cache_path: cache_path, relative_paths_root: local_cookbooks_root )
  end

  let(:solution_dependencies) do
    {
      "Policyfile" => [],
      "dependencies" => {
        "foo (1.0.0)" => [],
        "local-cookbook (2.3.4)" => [],
      },
    }
  end

  let(:lock_generator) do
    ChefDK::PolicyfileLock.build(storage_config) do |policy|

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

      policy.solution_dependencies.consume_lock_data(solution_dependencies)
    end
  end

  let(:lock_data) do
    lock_generator.to_lock
  end

  # Eagerly evaluate #policyfile_lock. This is necessary because many of
  # the tests follow this general process:
  # 1. setup valid state, generate a lockfile in-memory
  # 2. make the state invalid
  # 3. ensure validation detected the invalid state
  #
  # With lazy evaluation, #1 may happen after #2.
  let!(:policyfile_lock) do
    ChefDK::PolicyfileLock.new(storage_config).build_from_lock_data(lock_data)
  end

  let(:local_cookbook_path) { File.join(local_cookbooks_root, "local-cookbook") }

  context "when no cookbooks have changed" do

    it "validation succeeds" do
      expect(policyfile_lock.validate_cookbooks!).to be true
    end

  end

  describe "when a :path sourced cookbook has changed" do

    let(:metadata_path) { File.join(local_cookbook_path, "metadata.rb") }

    let(:cookbook_lock_data) { policyfile_lock.lock_data_for("local-cookbook") }

    # Validate the metadata is correct, so we know the test setup code
    # hasn't done something wrong.
    def ensure_metadata_as_expected!
      expected_metadata_rb = <<~E
        name             'local-cookbook'
        maintainer       ''
        maintainer_email ''
        license          ''
        description      'Installs/Configures local-cookbook'
        long_description 'Installs/Configures local-cookbook'
        version          '2.3.4'

      E
      expect(IO.read(metadata_path)).to eq(expected_metadata_rb)
    end

    context "when the cookbook is missing" do

      before do
        FileUtils.rm_rf(local_cookbook_path)
      end

      it "reports the missing cookbook and fails validation" do
        full_path = File.expand_path(local_cookbook_path)
        message = "Cookbook `local-cookbook' not found at path source `local-cookbook` (full path: `#{full_path}')"

        expect { policyfile_lock.validate_cookbooks! }.to raise_error(ChefDK::LocalCookbookNotFound, message)
      end

    end

    context "when the cookbook has an incorrect name" do

      let(:new_metadata) do
        <<~E
          name             'WRONG'
          maintainer       ''
          maintainer_email ''
          license          ''
          description      'Installs/Configures local-cookbook'
          long_description 'Installs/Configures local-cookbook'
          version          '2.3.4'

        E
      end

      before do
        ensure_metadata_as_expected!
        with_file(metadata_path) { |f| f.print(new_metadata) }
      end

      it "reports the unexpected cookbook and fails validation" do
        policyfile_lock

        message = "The cookbook at path source `local-cookbook' is expected to be named `local-cookbook', but is now named `WRONG' (full path: #{local_cookbook_path})"
        expect { policyfile_lock.validate_cookbooks! }.to raise_error(ChefDK::MalformedCookbook, message)
      end

    end

    context "when the cookbook has an updated version that violates no dependency constraints" do

      let(:new_metadata) do
        <<~E
          name             'local-cookbook'
          maintainer       ''
          maintainer_email ''
          license          ''
          description      'Installs/Configures local-cookbook'
          long_description 'Installs/Configures local-cookbook'
          version          '2.3.5' # changed from 2.3.4

        E
      end

      before do
        ensure_metadata_as_expected!
        with_file(metadata_path) { |f| f.print(new_metadata) }
        policyfile_lock.validate_cookbooks! # no error
      end

      it "updates the version information in the lockfile" do
        expect(cookbook_lock_data.version).to eq("2.3.5")
      end

      it "updates the content identifier" do
        old_id = lock_generator.lock_data_for("local-cookbook").identifier
        expect(cookbook_lock_data.identifier).to_not eq(old_id)
        expect(cookbook_lock_data.identifier).to eq("5a2b09f9d5e6e8a1a2d811c41d58ed200599adbe")
      end

      it "has an updated version and identifier" do
        expect(cookbook_lock_data).to be_updated
        expect(cookbook_lock_data.version_updated?).to be true
        expect(cookbook_lock_data.identifier_updated?).to be true
      end
    end

    context "when the cookbook has an updated version that violates other dependency constraints" do

      let(:solution_dependencies) do
        {
          "Policyfile" => [],
          "dependencies" => {
            "foo (1.0.0)" => [ [ "local-cookbook", "~> 2.0" ] ],
          },
        }
      end

      let(:new_metadata) do
        <<~E
          name             'local-cookbook'
          maintainer       ''
          maintainer_email ''
          license          ''
          description      'Installs/Configures local-cookbook'
          long_description 'Installs/Configures local-cookbook'
          version          '3.0.0' # changed from 2.3.4, violates `~> 2.0` constraint

        E
      end

      before do
        ensure_metadata_as_expected!
        with_file(metadata_path) { |f| f.print(new_metadata) }
      end

      it "reports the dependency conflict and fails validation" do
        expected_message = "Cookbook local-cookbook (3.0.0) conflicts with other dependencies:\nfoo (1.0.0) depends on local-cookbook ~> 2.0"
        expect { policyfile_lock.validate_cookbooks! }.to raise_error(ChefDK::DependencyConflict, expected_message)
      end

    end

    context "when a :path sourced cookbook has updated content" do

      let(:recipe_path) { File.join(local_cookbook_path, "recipes/default.rb") }

      let(:new_recipe) do
        <<~E
          # This is totally new code,
          # it is different than the old code

        E
      end

      before do
        ensure_metadata_as_expected!
        with_file(recipe_path) { |f| f.print(new_recipe) }
        policyfile_lock.validate_cookbooks! # no error
      end

      it "updates the lockfile with the new checksum and validation succeeds" do
        old_id = lock_generator.lock_data_for("local-cookbook").identifier

        expect(cookbook_lock_data.identifier).to_not eq(old_id)
        expect(cookbook_lock_data.identifier).to eq("0f62422f744d173c35a3e74f1a8c76c8b92908c2")
      end

      it "has an updated identifier but not an updated version" do
        expect(cookbook_lock_data).to be_updated
        expect(cookbook_lock_data.version_updated?).to be false
        expect(cookbook_lock_data.identifier_updated?).to be true
      end

    end

    context "when a :path source cookbook has added a dependency satisfied by the current cookbook set" do

      let(:new_metadata) do
        <<~E
          name             'local-cookbook'
          maintainer       ''
          maintainer_email ''
          license          ''
          description      'Installs/Configures local-cookbook'
          long_description 'Installs/Configures local-cookbook'
          version          '2.3.4'

          depends "foo", "=1.0.0"

        E
      end

      before do
        ensure_metadata_as_expected!
        with_file(metadata_path) { |f| f.print(new_metadata) }
        policyfile_lock.validate_cookbooks! # no error
      end

      it "updates the lockfile with the new checksum and validation succeeds" do
        old_id = lock_generator.lock_data_for("local-cookbook").identifier

        expect(cookbook_lock_data.identifier).to_not eq(old_id)
        expect(cookbook_lock_data.identifier).to eq("af5e1252307bdf99b878ca5ede3c40e24ee9e45a")
      end

      it "has an updated identifier but not an updated version" do
        expect(cookbook_lock_data).to be_updated
        expect(cookbook_lock_data.version_updated?).to be false
        expect(cookbook_lock_data.identifier_updated?).to be true
      end

      it "has an updated dependency set" do
        actual = policyfile_lock.solution_dependencies.to_lock["dependencies"]
        expected = {
          "local-cookbook (2.3.4)" => [ ["foo", "= 1.0.0"] ],
          "foo (1.0.0)" => [],
        }
        expect(actual).to eq(expected)
      end

    end

    context "when a :path source cookbook has added a dependency not satisfied by the current cookbook set" do

      let(:new_metadata) do
        <<~E
          name             'local-cookbook'
          maintainer       ''
          maintainer_email ''
          license          ''
          description      'Installs/Configures local-cookbook'
          long_description 'Installs/Configures local-cookbook'
          version          '2.3.4'

          depends "not-a-thing"

        E
      end

      before do
        ensure_metadata_as_expected!
        with_file(metadata_path) { |f| f.print(new_metadata) }
      end

      it "reports the not-satisfied dependency and validation fails" do
        error_message = "Cookbook local-cookbook (2.3.4) has dependency constraints that cannot be met by the existing cookbook set:\n" +
          "Cookbook not-a-thing isn't included in the existing cookbook set."
        expect { policyfile_lock.validate_cookbooks! }.to raise_error(ChefDK::DependencyConflict, error_message)
      end

    end

    context "when a :path source cookbook has modified a dep constraint and the new constraint is satisfied" do

      let(:solution_dependencies) do
        {
          "Policyfile" => [],
          "dependencies" => {
            "foo (1.0.0)" => [],
            "local-cookbook (2.3.4)" => [ ["foo", ">= 0.0.0"] ],
          },
        }
      end

      let(:new_metadata) do
        <<~E
          name             'local-cookbook'
          maintainer       ''
          maintainer_email ''
          license          ''
          description      'Installs/Configures local-cookbook'
          long_description 'Installs/Configures local-cookbook'
          version          '2.3.4'

          depends "foo", ">= 1.0.0"

        E
      end

      before do
        ensure_metadata_as_expected!
        with_file(metadata_path) { |f| f.print(new_metadata) }
        policyfile_lock.validate_cookbooks! # no error
      end

      it "updates the lockfile with the new checksum and validation succeeds" do
        actual = policyfile_lock.solution_dependencies.to_lock["dependencies"]
        expected = {
          "local-cookbook (2.3.4)" => [ ["foo", ">= 1.0.0"] ],
          "foo (1.0.0)" => [],
        }
        expect(actual).to eq(expected)
      end

    end

    context "when a :path source cookbook has modified a dep constraint and the new constraint is not satisfied" do

      let(:new_metadata) do
        <<~E
          name             'local-cookbook'
          maintainer       ''
          maintainer_email ''
          license          ''
          description      'Installs/Configures local-cookbook'
          long_description 'Installs/Configures local-cookbook'
          version          '2.3.4'

          depends "foo", "~> 2.0"

        E
      end

      before do
        ensure_metadata_as_expected!
        with_file(metadata_path) { |f| f.print(new_metadata) }
      end

      it "reports the not-satisfied dependency and validation fails" do
        error_message = "Cookbook local-cookbook (2.3.4) has dependency constraints that cannot be met by the existing cookbook set:\n" +
          "Dependency on foo ~> 2.0 conflicts with existing version foo (1.0.0)"
        expect { policyfile_lock.validate_cookbooks! }.to raise_error(ChefDK::DependencyConflict, error_message)
      end

    end

    context "when a :path source cookbook has updated it's version and another path source cookbook has updated its constraint" do

      # The situation we want to test here is when the user modifies a
      # cookbook's version, and also the dependency constraint on that cookbook
      # in a different cookbook. For example, cookbook A depends on B ~> 1.0,
      # then the user updates A to depend on B ~> 2.0, and bumps the version of B to 2.0.

      let(:lock_generator) do
        ChefDK::PolicyfileLock.build(storage_config) do |policy|

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

          policy.local_cookbook("another-local-cookbook") do |c|
            c.source = "another-local-cookbook"
            c.source_options = { path: "another-local-cookbook" }
          end
          policy.solution_dependencies.consume_lock_data(solution_dependencies)
        end
      end

      # Represents dependencies before modification
      let(:solution_dependencies) do
        {
          "Policyfile" => [],
          "dependencies" => {
            "foo (1.0.0)" => [],
            "local-cookbook (2.3.4)" => [ ],
            "another-local-cookbook (0.1.0)" => [ ["local-cookbook", "= 2.3.4"] ],
          },
        }
      end

      let(:new_metadata_local_cookbook) do
        <<~E
          name             'local-cookbook'
          maintainer       ''
          maintainer_email ''
          license          ''
          description      'Installs/Configures local-cookbook'
          long_description 'Installs/Configures local-cookbook'
          version          '3.0.0' # changed from 2.3.4

        E
      end

      let(:new_metadata_another_local_cookbook) do
        <<~E
          name             'another-local-cookbook'
          maintainer       ''
          maintainer_email ''
          license          ''
          description      'Installs/Configures another-local-cookbook'
          long_description 'Installs/Configures another-local-cookbook'
          version          '0.1.0'

          # This dep now requires the updated version of 'local-cookbook'
          depends 'local-cookbook', '= 3.0.0'
        E
      end

      let(:metadata_path_another_local_cookbook) do
        File.join(local_cookbooks_root, "another-local-cookbook", "metadata.rb")
      end

      before do
        ensure_metadata_as_expected!
        with_file(metadata_path) { |f| f.print(new_metadata_local_cookbook) }
        with_file(metadata_path_another_local_cookbook) { |f| f.print(new_metadata_another_local_cookbook) }
        policyfile_lock.validate_cookbooks! # no error
      end

      context "and the new constraint is satisfied by they new version" do

        it "updates the version and constraint in the lockfile (validation succeeds)" do
          actual = policyfile_lock.solution_dependencies.to_lock["dependencies"]
          expected = {
            "local-cookbook (3.0.0)" => [ ],
            "another-local-cookbook (0.1.0)" => [ [ "local-cookbook", "= 3.0.0" ] ],
            "foo (1.0.0)" => [],
          }
          expect(actual).to eq(expected)
        end

      end

    end

  end

  # Cached cookbook is both supermarket and git
  context "when a cached cookbook is modified" do

    let(:cached_cookbook_path) { File.join(cache_path, "foo-1.0.0") }

    let(:metadata_path) { File.join(cached_cookbook_path, "metadata.rb") }

    # Validate the metadata is correct, so we know the test setup code
    # hasn't done something wrong.
    def ensure_metadata_as_expected!
      expected_metadata_rb = <<~E
        name             'foo'
        maintainer       ''
        maintainer_email ''
        license          ''
        description      'Installs/Configures foo'
        long_description 'Installs/Configures foo'
        version          '1.0.0'

      E
      expect(IO.read(metadata_path)).to eq(expected_metadata_rb)
    end

    context "when the cookbook missing" do

      before do
        ensure_metadata_as_expected!
        FileUtils.rm_rf(cached_cookbook_path)
      end

      it "reports the missing cookbook and fails validation" do
        message = "Cookbook `foo' not found at expected cache location `foo-1.0.0' (full path: `#{cached_cookbook_path}')"
        expect { policyfile_lock.validate_cookbooks! }.to raise_error(ChefDK::CachedCookbookNotFound, message)
      end

    end

    context "when the content has changed" do

      # This basically means the user modified the cached cookbook. There's no
      # technical reason we need to be whiny about this, but if we treat it like
      # we would a path cookbook, you could end up with two cookbooks that look
      # like the canonical (e.g.) apache2 1.2.3 cookbook from supermarket with no
      # indication of which is which.
      #
      # We'll treat it like an error, but we need to provide a "pristine"
      # function to let the user recover.

      let(:new_metadata) do
        <<~E
          # This is a cached copy of an upstream cookbook, I should not be editing it but
          # YOLO
          name             'foo'
          maintainer       ''
          maintainer_email ''
          license          ''
          description      'Installs/Configures foo'
          long_description 'Installs/Configures foo'
          version          '1.0.0'
        E
      end

      before do
        ensure_metadata_as_expected!
        policyfile_lock
        with_file(metadata_path) { |f| f.print(new_metadata) }
      end

      it "reports the modified cached cookbook and validation fails" do
        message = "Cached cookbook `foo' (1.0.0) has been modified since the lockfile was generated. Cached cookbooks cannot be modified. (full path: `#{cached_cookbook_path}')"
        expect { policyfile_lock.validate_cookbooks! }.to raise_error(ChefDK::CachedCookbookModified, message)
      end
    end
  end
end
