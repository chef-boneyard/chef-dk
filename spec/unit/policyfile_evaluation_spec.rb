#
# Copyright:: Copyright (c) 2014-2018, Chef Software Inc.
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
require "chef-dk/policyfile_compiler"

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
          expect(policyfile.errors.size).to eq(1)
          expect(policyfile.errors.first).to match(/Invalid ruby syntax in policyfile 'TestPolicyfile.rb'/)
        end

      end

      context "Given a policyfile with a ruby error" do

        let(:policyfile_rb) { "raise 'oops'" }

        it "has an error message with code context" do
          expect(policyfile.errors.size).to eq(1)
          expected_message = <<~E
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

      context "when given an invalid run list item" do

        context "when there is only one colon between cookbook and recipe name" do

          let(:policyfile_rb) do
            <<-EOH
              name "hello"

              # Should be "foo::bar" (missing a colon)
              run_list "foo:bar"
            EOH
          end

          it "has an error message with the offending run list item" do
            expect(policyfile.errors).to_not be_empty
            expected_message = "Run List Item 'foo:bar' has invalid cookbook name 'foo:bar'.\n" +
              "Cookbook names can only contain alphanumerics, hyphens, and underscores.\n" +
              "Did you mean 'foo::bar'?"
            expect(policyfile.errors.first).to eq(expected_message)
          end
        end

        context "when there is only one colon between cookbook and recipe name in fully qualified form" do

          let(:policyfile_rb) do
            <<-EOH
              name "hello"

              # Should be "foo::bar" (missing a colon)
              run_list "recipe[foo:bar]"
            EOH
          end

          it "has an error message with the offending run list item" do
            expect(policyfile.errors).to_not be_empty
            expected_message = "Run List Item 'recipe[foo:bar]' has invalid cookbook name 'foo:bar'.\n" +
              "Cookbook names can only contain alphanumerics, hyphens, and underscores.\n" +
              "Did you mean 'recipe[foo::bar]'?"
            expect(policyfile.errors.first).to eq(expected_message)
          end
        end

        context "when the recipe name is empty" do

          let(:policyfile_rb) do
            <<-EOH
              name "hello"

              # Should be "foo::default" or just "foo"
              run_list "foo::"
            EOH
          end

          it "has an error message with the offending run list item" do
            expect(policyfile.errors).to_not be_empty
            expected_message = "Run List Item 'foo::' has invalid recipe name ''.\nRecipe names can only contain alphanumerics, hyphens, and underscores."
            expect(policyfile.errors.first).to eq(expected_message)
          end

        end

        context "with an invalid run list item in a named run list" do

          let(:policyfile_rb) do
            <<-EOH
              name "hello"

              # this one is valid:
              run_list "foo"

              named_run_list :oops, "foo:bar"
            EOH
          end

          it "has an error message with the offending run list item" do
            expect(policyfile.errors).to_not be_empty
            expected_message = "Named Run List 'oops' Item 'foo:bar' has invalid cookbook name 'foo:bar'.\n" +
              "Cookbook names can only contain alphanumerics, hyphens, and underscores.\n" +
              "Did you mean 'foo::bar'?"
            expect(policyfile.errors.first).to eq(expected_message)
          end

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
        expect(policyfile.run_list).to eq(%w{foo bar})
      end

      it "gives the run_list as the expanded run_list" do
        expect(policyfile.expanded_run_list).to eq(%w{foo bar})
      end

      it "has no default cookbook source" do
        expect(policyfile.default_source).to be_an(Array)
        expect(policyfile.default_source.size).to eq(1)
        expect(policyfile.default_source.first).to be_a(ChefDK::Policyfile::NullCookbookSource)
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
          expected = [ ChefDK::Policyfile::CommunityCookbookSource.new("https://supermarket.chef.io") ]
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
            expected = [ ChefDK::Policyfile::CommunityCookbookSource.new("https://cookbook-api.example.com") ]
            expect(policyfile.default_source).to eq(expected)
          end

        end

        context "with an added cookbook with no options" do

          let(:policyfile_rb) do
            <<-EOH
              run_list "foo", "bar"
              cookbook "baz"
            EOH
          end

          it "adds the cookbook to the list of location specs" do
            expect(policyfile.errors).to eq([])
            expected_cb_spec = ChefDK::Policyfile::CookbookLocationSpecification.new("baz", ">= 0.0.0", {}, storage_config)
            expect(policyfile.cookbook_location_specs).to eq("baz" => expected_cb_spec)
          end
        end

      end

      context "with the default source set to a delivery_supermarket" do

        context "when no URI is given" do

          let(:policyfile_rb) do
            <<-EOH
              run_list "foo", "bar"
              default_source :delivery_supermarket
            EOH
          end

          it "errors out with a message that the supermarket URI is required" do
            expect(policyfile.errors).to eq([ "You must specify the server's URI when using a default_source :delivery_supermarket" ])
          end

        end

        context "when the URI is given" do

          let(:policyfile_rb) do
            <<-EOH
              run_list "foo", "bar"
              default_source :delivery_supermarket, "https://supermarket.example.com"
            EOH
          end

          it "sets the default source to the delivery_supermarket" do
            expect(policyfile.errors).to eq([])
            expected = [ ChefDK::Policyfile::DeliverySupermarketSource.new("https://supermarket.example.com") ]
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
          expect(policyfile.errors).to eq([])
          expected = [ ChefDK::Policyfile::ChefServerCookbookSource.new("https://mychef.example.com") ]
          expect(policyfile.default_source).to eq(expected)
        end

      end

      context "with the default source set to a chef-repo path" do

        let(:chef_repo) { File.expand_path("spec/unit/fixtures/local_path_cookbooks", project_root) }

        let(:policyfile_rb) do
          <<-EOH
            run_list "foo", "bar"
            default_source :chef_repo, "#{chef_repo}"
          EOH
        end

        it "has a default source" do
          expect(policyfile.errors).to eq([])
          expected = [ ChefDK::Policyfile::ChefRepoCookbookSource.new(chef_repo) ]
          expect(policyfile.default_source).to eq(expected)
        end

        context "when the path to the chef repo is relative" do

          let(:policyfile_rb) do
            <<-EOH
              run_list "foo", "bar"
              default_source :chef_repo, "../cookbooks"
            EOH
          end

          # storage_config is created with path to Policyfile.rb in CWD
          let(:expected_path) { File.expand_path("../cookbooks") }

          it "sets the repo path relative to the directory the policyfile is in" do
            expect(policyfile.errors).to eq([])
            expect(policyfile.default_source.size).to eq(1)
            expect(policyfile.default_source.first).to be_a(ChefDK::Policyfile::ChefRepoCookbookSource)
            expect(policyfile.default_source.first.path).to eq(expected_path)
          end

        end

      end

      context "with multiple default sources" do
        let(:chef_repo) { File.expand_path("spec/unit/fixtures/local_path_cookbooks", project_root) }

        let(:policyfile_rb) do
          <<-EOH
            run_list "foo", "bar"

            default_source :community
            default_source :chef_repo, "#{chef_repo}"
          EOH
        end

        it "has an array of sources" do
          expect(policyfile.errors).to eq([])

          community_source = ChefDK::Policyfile::CommunityCookbookSource.new("https://supermarket.chef.io")
          repo_source = ChefDK::Policyfile::ChefRepoCookbookSource.new(chef_repo)
          expected = [ community_source, repo_source ]

          expect(policyfile.default_source).to eq(expected)
        end

      end

      context "with multiple supermarkets with source preferences set for specific cookbooks" do

        context "when the preferences don't conflict" do
          let(:policyfile_rb) do
            <<-EOH
              run_list "foo", "bar", "baz"

              default_source :supermarket do |s|
                s.preferred_for "foo"
              end

              default_source :supermarket, "https://mart.example" do |s|
                s.preferred_for "bar", "baz"
              end
            EOH
          end

          it "has an array of sources, with cookbook preferences set" do
            expect(policyfile.errors).to eq([])
            expect(policyfile.default_source.size).to eq(2)

            public_supermarket = policyfile.default_source.first
            expect(public_supermarket.preferred_cookbooks).to eq(%w{ foo })

            private_supermarket = policyfile.default_source.last
            expect(private_supermarket.uri).to eq("https://mart.example")
            expect(private_supermarket.preferred_cookbooks).to eq(%w{ bar baz })
          end

        end

        context "when the preferences conflict" do
          let(:policyfile_rb) do
            # both supermarkets are the preferred source for "foo"
            <<-EOH
              run_list "foo", "bar"

              default_source :supermarket do |s|
                s.preferred_for "foo"
              end

              default_source :supermarket, "https://mart.example" do |s|
                s.preferred_for "foo"
              end
            EOH
          end

          it "emits an error" do
            err = <<~MESSAGE
              Multiple sources are marked as the preferred source for some cookbooks. Only one source can be preferred for a cookbook.
              supermarket(https://supermarket.chef.io) and supermarket(https://mart.example) are both set as the preferred source for cookbook(s) 'foo'
            MESSAGE
            expect(policyfile.errors).to eq([err])
          end

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
          expected_cb_spec = ChefDK::Policyfile::CookbookLocationSpecification.new("foo", ">= 0.0.0", { path: "local_cookbooks/foo" }, storage_config)
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
          expected_cb_spec = ChefDK::Policyfile::CookbookLocationSpecification.new("foo", ">= 0.0.0", { git: "git://example.com:me/foo-cookbook.git" }, storage_config)
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

        it "sets the source of the cookbook to the git URL" do
          expected_cb_spec = ChefDK::Policyfile::CookbookLocationSpecification.new("foo", ">= 0.0.0", { chef_server: "https://mychefserver.example.com" }, storage_config)
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
        expected = <<~EOH
          Cookbook 'foo' assigned to conflicting sources

          Previous source: {:path=>"local_cookbooks/foo"}
          Conflicts with: {:chef_server=>"https://mychefserver.example.com"}
        EOH
        expect(policyfile.errors.size).to eq(1)
        expect(policyfile.errors.first).to eq(expected)
      end

    end

    describe "defining attributes" do

      let(:policyfile_rb) do
        <<-EOH
          name "policy-with-attrs"
          run_list "foo"

          # basic attribute setting:
          default["foo"] = "bar"

          # auto-vivify
          default["abc"]["def"]["ghi"] = "xyz"

          # literal data structures
          default["baz"] = {
            "more_nested_stuff" => "yup"
          }

          # Array literals work and we merge rather than overwrite:
          default["baz"]["an_array"] = ["a", "b", "c"]

          # all the same stuff works with overrides:

          override["foo"] = "bar"

          override["abc"]["def"]["ghi"] = "xyz"

          override["baz_override"] = {
            "more_nested_stuff" => "yup"
          }

          override["baz_override"]["an_array"] = ["a", "b", "c"]
        EOH
      end

      let(:expected_combined_default_attrs) do
        {
          "foo" => "bar",
          "abc" => { "def" => { "ghi" => "xyz" } },
          "baz" => {
            "more_nested_stuff" => "yup",
            "an_array" => %w{a b c},
          },
        }
      end

      let(:expected_combined_override_attrs) do
        {
          "foo" => "bar",
          "abc" => { "def" => { "ghi" => "xyz" } },
          "baz_override" => {
            "more_nested_stuff" => "yup",
            "an_array" => %w{a b c},
          },
        }
      end

      it "defines default attributes" do
        expect(policyfile.errors).to eq([])
        expect(policyfile.default_attributes).to eq(expected_combined_default_attrs)
      end

      it "defines override attributes" do
        expect(policyfile.errors).to eq([])
        expect(policyfile.override_attributes).to eq(expected_combined_override_attrs)
      end
    end

  end

end
