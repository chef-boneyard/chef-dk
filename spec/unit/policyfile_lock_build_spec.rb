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
require 'shared/setup_git_cookbooks'
require 'shared/fixture_cookbook_checksums'
require 'chef-dk/policyfile/storage_config'
require 'chef-dk/policyfile_lock.rb'

describe ChefDK::PolicyfileLock, "building a lockfile" do

  include_context "fixture cookbooks checksums"

  # For debugging giant nested hashes...
  def expect_hash_equal(actual, expected)
    expected.each do |key, expected_value|
      expect(actual).to have_key(key)
      if expected_value.kind_of?(Hash)
        expect_hash_equal(actual[key], expected_value)
      else
        expect(actual[key]).to eq(expected_value)
      end
    end
    expect(actual).to eq(expected)
  end

  let(:cache_path) do
    File.expand_path("spec/unit/fixtures/cookbook_cache", project_root)
  end

  let(:relative_paths_root) do
    File.expand_path("spec/unit/fixtures/", project_root)
  end

  let(:storage_config) do
    ChefDK::Policyfile::StorageConfig.new( cache_path: cache_path, relative_paths_root: relative_paths_root )
  end

  context "when a cached cookbook omits the cache key" do

    let(:policyfile_lock) do
      ChefDK::PolicyfileLock.build(storage_config) do |p|

        p.name = "invalid_cache_key_policyfile"

        p.run_list = [ "recipe[foo]" ]

        p.cached_cookbook("nosuchthing") do |cb|
        end
      end
    end

    it "raises a descriptive error" do
      expect { policyfile_lock.to_lock }.to raise_error(ChefDK::CachedCookbookNotFound)
    end

  end

  context "when a local cookbook omits the path" do

    let(:policyfile_lock) do
      ChefDK::PolicyfileLock.build(storage_config) do |p|

        p.name = "invalid_local_cookbook"

        p.run_list = [ "recipe[foo]" ]

        p.local_cookbook("nosuchthing") do |cb|
        end
      end
    end

    it "raises a descriptive error" do
      expect { policyfile_lock.to_lock }.to raise_error(ChefDK::LocalCookbookNotFound)
    end
  end

  context "when a local cookbook has an incorrect path" do

    let(:policyfile_lock) do
      ChefDK::PolicyfileLock.build(storage_config) do |p|

        p.name = "invalid_local_cookbook"

        p.run_list = [ "recipe[foo]" ]

        p.local_cookbook("nosuchthing") do |cb|
          cb.source = "nopenopenope"
        end
      end
    end

    it "raises a descriptive error" do
      expect { policyfile_lock.to_lock }.to raise_error(ChefDK::LocalCookbookNotFound)
    end
  end

  context "when a cookbook is not in the cache" do

    let(:policyfile_lock) do
      ChefDK::PolicyfileLock.build(storage_config) do |p|

        p.name = "invalid_cache_key_policyfile"

        p.run_list = [ "recipe[foo]" ]

        p.cached_cookbook("nosuchthing") do |cb|
          cb.cache_key = "nosuchthing-1.0.0"
        end
      end
    end

    it "raises a descriptive error" do
      expect { policyfile_lock.to_lock }.to raise_error(ChefDK::CachedCookbookNotFound)
    end

  end

  context "with a minimal policyfile" do

    let(:policyfile_lock) do
      ChefDK::PolicyfileLock.build(storage_config) do |p|

        p.name = "minimal_policyfile"

        p.run_list = [ "recipe[foo]" ]
        p.cached_cookbook("foo") do |cb|
          cb.cache_key = "foo-1.0.0"
        end

      end
    end

    let(:compiled_policyfile) do
      {

        "name" => "minimal_policyfile",

        "run_list" => ["recipe[foo]"],

        "cookbook_locks" => {

          "foo" => {
            "version" => "1.0.0",
            "identifier" => cookbook_foo_cksum,
            "dotted_decimal_identifier" => cookbook_foo_cksum_dotted,
            "cache_key" => "foo-1.0.0",
            "origin" => nil,
            "source_options" => nil
          },
        },
        "solution_dependencies" => { "Policyfile" => [], "dependencies" => {} }
      }
    end

    it "has a cache path" do
      expect(policyfile_lock.cache_path).to eq(cache_path)
    end

    it "computes a minimal policyfile" do
      expect(policyfile_lock.to_lock).to eq(compiled_policyfile)
    end

  end

  context "with a policyfile containing a local cookbook" do

    include_context "setup git cookbooks"
    include_context "setup git cookbook remote"

    let(:relative_paths_root) do
      tempdir
    end

    let(:policyfile_lock) do
      ChefDK::PolicyfileLock.build(storage_config) do |p|

        p.name = "dev_cookbook"

        p.run_list = [ "recipe[bar]" ]
        p.local_cookbook("bar") do |cb|
          cb.source = "bar"
        end

      end
    end

    let(:compiled_policyfile) do
      {

        "name" => "dev_cookbook",

        "run_list" => ["recipe[bar]"],

        "cookbook_locks" => {

          "bar" => {
            "version" => "0.1.0",
            "identifier" => cookbook_bar_cksum,
            "dotted_decimal_identifier" => cookbook_bar_cksum_dotted,

            "source" => "bar",
            "cache_key" => nil,
            "scm_info" => {
              "scm" => "git",
              "remote" => remote_url,
              "revision" => current_rev,
              "working_tree_clean" => true,
              "published" => true,
              "synchronized_remote_branches"=>["origin/master"]
            },
            "source_options" => nil
          },
        },
        "solution_dependencies" => { "Policyfile" => [], "dependencies" => {} }
      }
    end

    it "computes a lockfile including git data" do
      actual_lock = policyfile_lock.to_lock
      expect(actual_lock).to eq(compiled_policyfile)
    end
  end

  context "with a policyfile using custom identifiers" do

    include_context "setup git cookbooks"

    let(:relative_paths_root) do
      tempdir
    end

    let(:policyfile_lock) do
      ChefDK::PolicyfileLock.build(storage_config) do |p|

        p.name = "custom_identifier"

        p.run_list = [ "recipe[foo]" ]

        p.cached_cookbook("foo") do |cb|
          cb.cache_key = "foo-1.0.0"

          # Explicitly set the identifier and dotted decimal identifiers to the
          # version number (but it could be anything).
          cb.identifier = "1.0.0"
          cb.dotted_decimal_identifier ="1.0.0"
        end

        p.local_cookbook("bar") do |cb|
          cb.source = "bar"
          cb.identifier = "0.1.0"
          cb.dotted_decimal_identifier = "0.1.0"
        end
      end

    end

    let(:compiled_policyfile) do
      {

        "name" => "custom_identifier",

        "run_list" => ["recipe[foo]"],

        "cookbook_locks" => {

          "foo" => {
            "version" => "1.0.0",
            "identifier" => "1.0.0",
            "dotted_decimal_identifier" => "1.0.0",
            "cache_key" => "foo-1.0.0",
            "origin" => nil,
            "source_options" => nil
          },

          "bar" => {
            "version" => "0.1.0",
            "identifier" => "0.1.0",
            "dotted_decimal_identifier" => "0.1.0",

            "source" => "bar",
            "cache_key" => nil,
            "scm_info" => {
              "scm" => "git",
              "remote" => nil,
              "revision" => current_rev,
              "working_tree_clean" => true,
              "published" => false,
              "synchronized_remote_branches"=>[]
            },
            "source_options" => nil
          },
        },
        "solution_dependencies" => { "Policyfile" => [], "dependencies" => {} }
      }
    end

    it "generates a lockfile with custom identifiers" do
      expect(policyfile_lock.to_lock).to eq(compiled_policyfile)
    end

  end

  context "with a policyfile lock with a mix of cached and local cookbooks" do

    include_context "setup git cookbooks"

    let(:relative_paths_root) do
      tempdir
    end

    let(:policyfile_lock) do

      ChefDK::PolicyfileLock.build(storage_config) do |p|

        # Required
        p.name = "basic_example"

        # Required. Should be fully expanded without roles
        p.run_list = ["recipe[foo]", "recipe[bar]", "recipe[baz::non_default]"]

        # A cached_cookbook is stored in the cache directory in a subdirectory
        # given by 'cache_key'. It is assumed to be static (not modified by the
        # user).
        p.cached_cookbook("foo") do |cb|
          cb.cache_key = "foo-1.0.0"

          # Optional attribute that humans can use to understand where a cookbook
          # came from.
          cb.origin = "https://community.getchef.com/api/cookbooks/foo/1.0.0"
        end

        p.local_cookbook("bar") do |cb|
          cb.source = "bar"
        end

        p.cached_cookbook("baz") do |cb|
          cb.cache_key = "baz-f59ee7a5bca6a4e606b67f7f856b768d847c39bb"
          cb.origin = "git://github.com/opscode-cookbooks/bar.git"
        end

        p.cached_cookbook("dep_of_bar") do |cb|
          cb.cache_key = "dep_of_bar-1.2.3"
          cb.origin = "https://chef-server.example.com/cookbooks/dep_of_bar/1.2.3"
        end
      end

    end


    let(:compiled_policyfile) do
      {

        "name" => "basic_example",

        "run_list" => ["recipe[foo]", "recipe[bar]", "recipe[baz::non_default]"],

        "cookbook_locks" => {

          "foo" => {
            "version" => "1.0.0",
            "identifier" => cookbook_foo_cksum,
            "dotted_decimal_identifier" => cookbook_foo_cksum_dotted,
            "origin" => "https://community.getchef.com/api/cookbooks/foo/1.0.0",
            "cache_key" => "foo-1.0.0",
            "source_options" => nil
          },

          "bar" => {
            "version" => "0.1.0",
            "identifier" => cookbook_bar_cksum,
            "dotted_decimal_identifier" => cookbook_bar_cksum_dotted,
            "source" => "bar",
            "cache_key" => nil,

            "scm_info" => {
              "scm" => "git",
              "remote" => nil,
              "revision" => current_rev,
              "working_tree_clean" => true,
              "published" => false,
              "synchronized_remote_branches"=>[]
            },
            "source_options" => nil
          },

          "baz" => {
            "version" => "1.2.3",
            "identifier"=> cookbook_baz_cksum,
            "dotted_decimal_identifier" => cookbook_baz_cksum_dotted,
            "cache_key" => "baz-f59ee7a5bca6a4e606b67f7f856b768d847c39bb",
            "origin" => "git://github.com/opscode-cookbooks/bar.git",
            "source_options" => nil
          },

          "dep_of_bar" => {
            "version" => "1.2.3",
            "identifier" => cookbook_dep_of_bar_cksum,
            "dotted_decimal_identifier" => cookbook_dep_of_bar_cksum_dotted,
            "origin" => "https://chef-server.example.com/cookbooks/dep_of_bar/1.2.3",
            "cache_key" => "dep_of_bar-1.2.3",
            "source_options" => nil

          },

        },

        "solution_dependencies" => { "Policyfile" => [], "dependencies" => {} }

      }
    end

    it "generates a lockfile with the relevant profile data for each cookbook" do
      generated = policyfile_lock.to_lock
      expect(generated['name']).to eq(compiled_policyfile['name'])
      expect(generated['run_list']).to eq(compiled_policyfile['run_list'])

      generated_locks = generated['cookbook_locks']
      expected_locks = compiled_policyfile['cookbook_locks']

      # test individually so failures are easier to read
      expect(generated_locks['foo']).to eq(expected_locks['foo'])
      expect(generated_locks['bar']).to eq(expected_locks['bar'])
      expect(generated_locks['baz']).to eq(expected_locks['baz'])
      expect(generated_locks['dep_of_bar']).to eq(expected_locks['dep_of_bar'])

      expect(policyfile_lock.to_lock).to eq(compiled_policyfile)
    end

  end

  context "with solution dependencies specified" do

    let(:policyfile_lock) do
      ChefDK::PolicyfileLock.build(storage_config) do |p|

        p.name = "minimal_policyfile"

        p.run_list = [ "recipe[foo]" ]
        p.cached_cookbook("foo") do |cb|
          cb.cache_key = "foo-1.0.0"
        end

        p.dependencies do |deps|
          deps.add_cookbook_dep("foo", "1.0.0", [])
        end

      end
    end

    let(:compiled_policyfile) do
      {

        "name" => "minimal_policyfile",

        "run_list" => ["recipe[foo]"],

        "cookbook_locks" => {

          "foo" => {
            "version" => "1.0.0",
            "identifier" => cookbook_foo_cksum,
            "dotted_decimal_identifier" => cookbook_foo_cksum_dotted,
            "cache_key" => "foo-1.0.0",
            "origin" => nil,
            "source_options" => nil
          },
        },
        "solution_dependencies" => {
          "Policyfile" => [],
          "dependencies" => {"foo (1.0.0)" => []}
        }
      }
    end

    it "computes a minimal policyfile" do
      expect(policyfile_lock.to_lock).to eq(compiled_policyfile)
    end

  end
  describe "building a policyfile lock from a policyfile compiler" do

    include_context "setup git cookbooks"

    let(:relative_paths_root) do
      tempdir
    end

    let(:cached_cookbook_uri) { "https://supermarket.getchef.com/api/v1/cookbooks/foo/versions/1.0.0/download" }

    let(:cached_location_spec) do
      double( "ChefDK::Policyfile::CookbookLocationSpecification",
              mirrors_canonical_upstream?: true,
              cache_key: "foo-1.0.0",
              uri: cached_cookbook_uri,
              source_options_for_lock: { "artifactserver" => cached_cookbook_uri, "version" => "1.0.0" })
    end

    let(:local_location_spec) do
      double( "ChefDK::Policyfile::CookbookLocationSpecification",
              mirrors_canonical_upstream?: false,
              relative_paths_root: relative_paths_root,
              relative_path: "bar",
              source_options_for_lock: { "path" => "bar" })
    end

    let(:policyfile_solution_dependencies) do
      ChefDK::Policyfile::SolutionDependencies.new.tap do |s|
        s.add_policyfile_dep("foo", "~> 1.0")
        s.add_cookbook_dep("foo", "1.0.0", [])
        s.add_cookbook_dep("bar", "0.1.0", [])
      end
    end

    let(:policyfile_compiler) do
      double( "ChefDK::PolicyfileCompiler",
              name: "my-policyfile",
              normalized_run_list: %w[recipe[foo::default] recipe[bar::default]],
              all_cookbook_location_specs: {"foo" => cached_location_spec, "bar" => local_location_spec},
              solution_dependencies: policyfile_solution_dependencies )
    end

    let(:policyfile_lock) do
      ChefDK::PolicyfileLock.build_from_compiler(policyfile_compiler, storage_config)
    end

    let(:compiled_policyfile) do
      {

        "name" => "my-policyfile",

        "run_list" => ["recipe[foo::default]", "recipe[bar::default]"],

        "cookbook_locks" => {

          "foo" => {
            "version" => "1.0.0",
            "identifier" => cookbook_foo_cksum,
            "dotted_decimal_identifier" => cookbook_foo_cksum_dotted,
            "cache_key" => "foo-1.0.0",
            "origin" => cached_cookbook_uri,
            "source_options" => { "artifactserver" => cached_cookbook_uri, "version" => "1.0.0" }
          },

          "bar" => {
            "version" => "0.1.0",
            "identifier" => cookbook_bar_cksum,
            "dotted_decimal_identifier" => cookbook_bar_cksum_dotted,
            "source" => "bar",
            "cache_key" => nil,

            "scm_info" => {
              "scm" => "git",
              "remote" => nil,
              "revision" => current_rev,
              "working_tree_clean" => true,
              "published" => false,
              "synchronized_remote_branches"=>[]
            },
            "source_options" => { "path" => "bar" }
          }
        },

        "solution_dependencies" => {
          "Policyfile" => [ [ "foo", "~> 1.0" ] ],
          "dependencies" => { "foo (1.0.0)" => [], "bar (0.1.0)" => [] }
        }
      }
    end

    it "adds a cached cookbook lock generator for the compiler's cached cookbook" do
      expect(policyfile_lock.cookbook_locks).to have_key("foo")
      cb_lock = policyfile_lock.cookbook_locks["foo"]
      expect(cb_lock.origin).to eq(cached_location_spec.uri)
      expect(cb_lock.cache_key).to eq(cached_location_spec.cache_key)
    end

    it "adds a local cookbook lock generator for the compiler's local cookbook" do
      expect(policyfile_lock.cookbook_locks).to have_key("bar")
      cb_lock = policyfile_lock.cookbook_locks["bar"]
      expect(cb_lock.source).to eq(local_location_spec.relative_path)
    end

    it "generates a lockfile data structure" do
      expect(policyfile_lock.to_lock).to eq(compiled_policyfile)
    end

  end

end
