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
require 'chef-dk/policyfile_compiler'
require 'chef-dk/cookbook_cache_manager'

describe ChefDK::CookbookCacheManager do

  def new_cache_manager(options={})
    ChefDK::CookbookCacheManager.new(policyfile, options)
  end

  let(:relative_root) { File.join(fixtures_path, 'local_path_cookbooks') }

  let(:cache_path) { tempdir }

  let(:policyfile) { ChefDK::PolicyfileCompiler.new }

  let(:cache_manager) { new_cache_manager( relative_root: relative_root ) }

  before do
    reset_tempdir
  end

  describe "handling initialization options" do

    it "uses the current working directory as the default relative root" do
      cache_manager = new_cache_manager
      expect(cache_manager.relative_root).to eq(Dir.pwd)
    end

    it "sets an explicit relative root" do
      expect(cache_manager.relative_root).to eq(relative_root)
    end

    it "sets a cache path" do
      cache_manager = new_cache_manager(cache_path: "/tmp/foo")
      expect(cache_manager.cache_path).to eq("/tmp/foo")
    end

  end

  describe "reading metadata of local cookbooks" do

    describe "looking up a cookbook that doesn't exist" do
      before do
        policyfile.dsl.cookbook('not-here', path: "not-here")
      end

      it "gives a detailed error" do
        expect { cache_manager.cookbook_version("not-here") }.to raise_error(ChefDK::LocalCookbookNotFound)
      end
    end

    describe "looking up a cookbook with no metadata.rb" do
      before do
        policyfile.dsl.cookbook('metadata-missing', path: "metadata-missing")
      end

      it "gives a detailed error" do
        expect { cache_manager.cookbook_version("metadata-missing") }.to raise_error(ChefDK::MalformedCookbook)
      end
    end

    describe "looking up a correctly formed cookbook" do

      before do
        policyfile.dsl.cookbook('local-cookbook', path: "local-cookbook")
      end

      it "gives the version of the local cookbook" do
        expect(cache_manager.cookbook_version("local-cookbook")).to eq("2.3.4")
      end

      it "gives the dependencies of the local cookbook" do
        pending
        expected_dependencies = { "2.3.4" => [ [ "local-cookbook-dep-one", "~> 1.0"] ] }
        expect(cache_manager.cookbook_dependencies("local-cookbook")).to eq(expected_dependencies)
      end

    end

  end

  describe "handling git-sourced cookbooks" do

    let(:git_url) do
      File.expand_path("dev_cookbooks/bar-cookbook.gitbundle", fixtures_path)
    end

    before do
      policyfile.dsl.cookbook('bar', git: git_url)
    end

    it "loads the cookbook into the cache" do
      pending
      # Post condition:
      # cookbook exists at $cache_path/bar-SHA
    end

    it "gives the version of the cookbook" do
      pending
      expect(cache_manager.cookbook_version("git-sourced-cookbook")).to eq("4.5.6")
    end

    it "gives the dependencies of the cookbook" do
      pending
      expected_dependencies = { "4.5.6" => [ [ "git-cookbook-dep-one", "~> 1.0"] ] }
      expect(cache_manager.cookbook_dependencies("git-sourced-cookbook")).to eq(expected_dependencies)
    end
  end

  context "when the community site is the default source" do

    it "fetches the universe graph" do
      pending
      expect(cache_manager.universe_graph).to eq(community_universe_graph)
    end

  end

end

