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

describe ChefDK::PolicyfileLock do

  def id_to_dotted(sha1_id)
    major = sha1_id[0...14]
    minor = sha1_id[14...28]
    patch = sha1_id[28..40]
    decimal_integers =[major, minor, patch].map {|hex| hex.to_i(16) }
    decimal_integers.join(".")
  end

  let(:cache_path) do
    File.expand_path("spec/unit/fixtures/cookbook_cache", project_root)
  end

  let(:policyfile_lock_options) do
    { cache_path: cache_path }
  end

  let(:complete_policyfile) do

    ChefDK::PolicyfileLock.build(policyfile_lock_options) do |p|

      # Required
      p.name = "basic_example"

      # Required. Should be fully expanded without roles
      p.runlist = ["recipe[foo]", "recipe[bar]", "recipe[baz::non_default]"]

      # A cached_cookbook is stored in the cache directory in a subdirectory
      # given by 'cache_key'. It is assumed to be static (not modified by the
      # user).
      p.cached_cookbook("foo") do |cb|
        cb.cache_key = "foo-1.0.0"

        # Optional attribute that humans can use to understand where a cookbook
        # came from.
        cb.origin = "https://community.getchef.com/api/cookbooks/foo/1.0.0"
      end

      p.cached_cookbook("bar") do |cb|
        cb.cache_key = "bar-f59ee7a5bca6a4e606b67f7f856b768d847c39bb"
        cb.origin = "git://github.com/opscode-cookbooks/bar.git"
      end

      p.local_cookbook("baz") do |cb|
        # for a local source, we assume the cookbook is in development and
        # could be modified, we will check the identifier before uploading
        cb.source = "my_cookbooks/baz"
      end

      p.cached_cookbook("dep_of_bar") do |cb|
        cb.cache_key = "dep_of_bar-1.2.3"
        cb.origin = "https://chef-server.example.com/cookbooks/dep_of_bar/1.2.3"
      end
    end

  end


  let(:complete_policyfile_compiled) do
    {

      "name" => "basic_example",

      "run_list" => ["recipe[foo]", "recipe[bar]", "recipe[baz::non_default]"],

      "cookbook_locks" => {

        "foo" => {
          "version" => "1.0.0",
          "identifier" => "168d2102fb11c9617cd8a981166c8adc30a6e915",
          "dotted_decimal_identifier" => id_to_dotted("168d2102fb11c9617cd8a981166c8adc30a6e915"),
          "origin" => "https://community.getchef.com/api/cookbooks/foo/1.0.0",
          "cache_key" => "foo-1.0.0"
        },

        "bar" => {
          "version" => "2.0.0",
          "identifier" => "feab40e1fca77c7360ccca1481bb8ba5f919ce3a",
          "dotted_decimal_identifier" => id_to_dotted("feab40e1fca77c7360ccca1481bb8ba5f919ce3a"),
          "origin" => "git://github.com/opscode-cookbooks/bar.git",
          "cache_key" => "bar-f59ee7a5bca6a4e606b67f7f856b768d847c39bb"
        },

        "baz" => {
          "version" => "1.2.3",
          "source" => "my_coookbooks/baz",
          "cache_key" => nil,
          "scm_info" => {
            "scm" => "git",
            # To get this info, you need to do something like:
            # figure out branch or assume 'master'
            # git config --get branch.master.remote
            # git config --get remote.opscode.url
            "remote" => "git@github.com:myorg/baz-cookbook.git",
            "ref" => "d867188a29db0ec438ae812a0fae90f3c267f38e",
            "working_tree_clean" => false,
            "published" => false
          },
        },

        "dep_of_bar" => {
          "version" => "1.2.3",
          "identifier" => "3d9d097332199fdafc3237c0ec11fcd784c11b4d",
          "dotted_decimal_identifier" => id_to_dotted("3d9d097332199fdafc3237c0ec11fcd784c11b4d"),
          "origin" => "https://chef-server.example.com/cookbooks/dep_of_bar/1.2.3",
          "cache_key" => "dep_of_bar-1.2.3",

        },

      },

    }
  end

  let(:minimal_policyfile) do
    ChefDK::PolicyfileLock.build(policyfile_lock_options) do |p|

      p.name = "minimal_policyfile"

      p.run_list = [ "recipe[foo]" ]
      p.cached_cookbook("foo") do |cb|
        cb.cache_key = "foo-1.0.0"
      end

    end
  end

  let(:minimal_policyfile_compiled) do
    {

      "name" => "minimal_policyfile",

      "run_list" => ["recipe[foo]"],

      "cookbook_locks" => {

        "foo" => {
          "version" => "1.0.0",
          "identifier" => "e4611e9b5ec0636a18979e7dd22537222a2eab47",
          "dotted_decimal_identifier" => id_to_dotted("e4611e9b5ec0636a18979e7dd22537222a2eab47"),
          "cache_key" => "foo-1.0.0"
        },
      }
    }
  end

  let(:custom_identifier_policyfile) do
    ChefDK::PolicyfileLock.build(policyfile_lock_options) do |p|

      p.name = "custom_identifier"

      p.run_list = [ "recipe[foo]" ]

      p.cached_cookbook("foo") do |cb|
        cb.cache_key = "foo-1.0.0"

        # Explicitly set the identifier and dotted decimal identifiers to the
        # version number (but it could be anything).
        cb.identifier = "1.0.0"
        cb.dotted_decimal_identifier ="1.0.0"
      end
    end

  end

  let(:custom_identifier_policyfile_compiled) do
    {

      "name" => "custom_identifier",

      "run_list" => ["recipe[foo]"],

      "cookbook_locks" => {

        "foo" => {
          "version" => "1.0.0",
          "identifier" => "1.0.0",
          "dotted_decimal_identifier" => "1.0.0",
          "origin" => "https://community.getchef.com/api/cookbooks/foo/1.0.0",
          "cache_key" => "foo-1.0.0"
        },
      }
    }
  end

  it "has a cache path" do
    expect(minimal_policyfile.cache_path).to eq(cache_path)
  end

  it "computes a minimal policyfile" do
    expect(minimal_policyfile.to_lock).to eq(minimal_policyfile_compiled)
  end

  context "when a cookbook is not in the cache" do

    let(:invalid_cache_key_policyfile) do
      ChefDK::PolicyfileLock.build(policyfile_lock_options) do |p|

        p.name = "invalid_cache_key_policyfile"

        p.run_list = [ "recipe[foo]" ]

        p.cached_cookbook("nosuchthing") do |cb|
          cb.cache_key = "nosuchthing-1.0.0"
        end
      end
    end

    it "raises a descriptive error" do
      pending
    end

  end
end
