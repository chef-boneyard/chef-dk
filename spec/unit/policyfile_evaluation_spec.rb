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

describe ChefDK::PolicyfileCompiler do

  let(:storage_config) { ChefDK::Policyfile::StorageConfig.new.use_policyfile("TestPolicyfile.rb") }

  let(:policyfile) { ChefDK::PolicyfileCompiler.evaluate(policyfile_rb, "TestPolicyfile.rb") }

  describe "Evaluate a policyfile" do

    describe "when the policyfile is not valid" do

      describe "when error! is called" do

        let(:policyfile_rb) { "raise 'oops'" }

        it "raises a PolicyfileError" do
          expect { policyfile.error! }.to raise_error(ChefDK::PolicyfileError)
        end
      end

      context "Given an empty policyfile" do

        let(:policyfile_rb) { "" }

        it "has an invalid run_list" do
          expect(policyfile.errors).to include("Invalid run_list. run_list cannot be empty")
        end

      end

      context "Given a policyfile with a syntax error" do

        let(:policyfile_rb) { "{{{{::::{{::" }

        it "has a syntax error message" do
          expected_error=<<-E
Invalid ruby syntax in policyfile 'TestPolicyfile.rb':

TestPolicyfile.rb:1: syntax error, unexpected :: at EXPR_BEG, expecting tCONSTANT
{{{{::::{{::
        ^
TestPolicyfile.rb:1: syntax error, unexpected end-of-input, expecting tCONSTANT
{{{{::::{{::
            ^
E
          expect(policyfile.errors.size).to eq(1)
          expect(policyfile.errors.first).to eq(expected_error.chomp)
        end

      end

      context "Given a policyfile with a ruby error" do

        let(:policyfile_rb) { "raise 'oops'" }

        it "has an error message with code context" do
          expect(policyfile.errors.size).to eq(1)
          expected_message = <<-E
Evaluation of policyfile 'TestPolicyfile.rb' raised an exception
  Exception: RuntimeError "oops"

  Relevant Code:
    1: raise 'oops'

  Backtrace:
    TestPolicyfile.rb:1:in `eval_policyfile'
E
          expect(policyfile.errors.first).to eq(expected_message)
        end
      end

      context "when policyfile evaluation is aborted by user signal" do

        let(:policyfile_rb) { "raise Interrupt" }

        it "allows the exception to bubble up" do
          expect { policyfile }.to raise_error(Interrupt)
        end
      end

      context "when given an invalid default source type" do

        let(:policyfile_rb) do
          <<-EOH
            run_list "foo"
            default_source :herp, "derp"
          EOH
        end

        it "has an invalid source error" do
          expect(policyfile.errors.size).to eq(1)
          expect(policyfile.errors.first).to eq("Invalid default_source type ':herp'")
        end
      end

      context "when the url is omitted for chef server default source" do
        let(:policyfile_rb) do
          <<-EOH
            run_list "foo"
            default_source :chef_server
          EOH
        end

        it "has an invalid source error" do
          expect(policyfile.errors.size).to eq(1)
          expect(policyfile.errors.first).to eq("You must specify the server's URI when using a default_source :chef_server")
        end

      end

      context "when a per-cookbook source is specified with invalid options" do
        let(:policyfile_rb) do
          <<-EOH
            run_list "foo"

            cookbook "foo", herp: "derp"
          EOH
        end

        it "has an invalid source error" do
          expect(policyfile.errors.size).to eq(1)
          message = "Cookbook `foo' has invalid source options `{:herp=>\"derp\"}'"
          expect(policyfile.errors.first).to eq(message)
        end
      end
    end

    context "Given a minimal valid policyfile" do

      let(:policyfile_rb) do
        <<-EOH
          name "hello"

          run_list "foo", "bar"
        EOH
      end

      it "has no errors" do
        expect(policyfile.errors).to eq([])
      end

      it "has a name" do
        expect(policyfile.name).to eq("hello")
      end

      it "has a run_list" do
        expect(policyfile.run_list).to eq(%w[foo bar])
      end

      it "gives the run_list as the expanded run_list" do
        expect(policyfile.expanded_run_list).to eq(%w[foo bar])
      end

      it "has no default cookbook source" do
        expect(policyfile.default_source).to be_a(ChefDK::Policyfile::NullCookbookSource)
      end

      context "with the default source set to the community site" do

        let(:policyfile_rb) do
          <<-EOH
            run_list "foo", "bar"
            default_source :community
          EOH
        end

        it "has a default source" do
          expect(policyfile.errors).to eq([])
          expected = ChefDK::Policyfile::CommunityCookbookSource.new("https://supermarket.chef.io")
          expect(policyfile.default_source).to eq(expected)
        end

        context "with a custom URI" do

          let(:policyfile_rb) do
            <<-EOH
              run_list "foo", "bar"
              default_source :community, "https://cookbook-api.example.com"
            EOH
          end

          it "has a default source" do
            expect(policyfile.errors).to eq([])
            expected = ChefDK::Policyfile::CommunityCookbookSource.new("https://cookbook-api.example.com")
            expect(policyfile.default_source).to eq(expected)
          end

        end

      end

      context "with the default source set to a chef server" do

        let(:policyfile_rb) do
          <<-EOH
            run_list "foo", "bar"
            default_source :chef_server, "https://mychef.example.com"
          EOH
        end

        it "has a default source" do
          skip "Chef server isn't yet supported in cookbook-omnifetch (pending /universe endpoint in Chef Server)"

          expect(policyfile.errors).to eq([])
          expected = ChefDK::Policyfile::ChefServerCookbookSource.new("https://mychef.example.com")
          expect(policyfile.default_source).to eq(expected)
        end

      end

    end

    describe "assigning cookbooks to specific sources" do

      before do
        expect(policyfile.errors).to eq([])
      end

      context "when a cookbook is assigned to a local source" do

        let(:policyfile_rb) do
          <<-EOH
            run_list "foo"
            cookbook "foo", path: "local_cookbooks/foo"
          EOH
        end

        it "sets the source of the cookbook to the local path" do
          expected_cb_spec = ChefDK::Policyfile::CookbookLocationSpecification.new("foo", ">= 0.0.0", {path: "local_cookbooks/foo"}, storage_config)
          expect(policyfile.cookbook_location_specs).to eq("foo" => expected_cb_spec)
        end

      end

      context "when a cookbook is assigned to a git source" do
        let(:policyfile_rb) do
          <<-EOH
            run_list "foo"
            cookbook "foo", git: "git://example.com:me/foo-cookbook.git"
          EOH
        end

        it "sets the source of the cookbook to the git URL" do
          expected_cb_spec = ChefDK::Policyfile::CookbookLocationSpecification.new("foo", ">= 0.0.0", {git: "git://example.com:me/foo-cookbook.git"}, storage_config)
          expect(policyfile.cookbook_location_specs).to eq("foo" => expected_cb_spec)
        end

      end

      context "when a cookbook is assigned to a chef_server source" do
        let(:policyfile_rb) do
          <<-EOH
            run_list "foo"
            cookbook "foo", chef_server: "https://mychefserver.example.com"
          EOH
        end

        # Chef server isn't yet supported in cookbook-omnifetch (pending /universe endpoint in Chef Server)
        # We have to skip at the example definition level or else we fail in the before block
        skip "sets the source of the cookbook to the git URL" do
          expected_cb_spec = ChefDK::Policyfile::CookbookLocationSpecification.new("foo", ">= 0.0.0", {chef_server: "https://mychefserver.example.com"}, storage_config)
          expect(policyfile.cookbook_location_specs).to eq("foo" => expected_cb_spec)
        end

      end

    end

    describe "assigning a cookbook to conflicting sources" do
      let(:policyfile_rb) do
        <<-EOH
          run_list "foo"
          cookbook "foo", path: "local_cookbooks/foo"
          cookbook "foo", chef_server: "https://mychefserver.example.com"
        EOH
      end

      it "has a conflicting sources error" do
        expected = <<-EOH
Cookbook 'foo' assigned to conflicting sources

Previous source: {:path=>"local_cookbooks/foo"}
Conflicts with: {:chef_server=>"https://mychefserver.example.com"}
EOH
        expect(policyfile.errors.size).to eq(1)
        expect(policyfile.errors.first).to eq(expected)
      end

    end

  end

end
