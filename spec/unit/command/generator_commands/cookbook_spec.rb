#
# Copyright:: Copyright (c) 2014-2019 Chef Software Inc.
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
require "shared/custom_generator_cookbook"
require "shared/setup_git_committer_config"
require "chef-dk/command/generator_commands/cookbook"

describe ChefDK::Command::GeneratorCommands::Cookbook do

  include_context("setup_git_committer_config")

  let(:argv) { %w{new_cookbook} }

  let(:stdout_io) { StringIO.new }
  let(:stderr_io) { StringIO.new }

  let(:expected_cookbook_file_relpaths) do
    %w{
      .gitignore
      .kitchen.yml
      test
      test/integration
      test/integration/default/default_test.rb
      Berksfile
      chefignore
      LICENSE
      metadata.rb
      README.md
      CHANGELOG.md
      recipes
      recipes/default.rb
      spec
      spec/spec_helper.rb
      spec/unit
      spec/unit/recipes
      spec/unit/recipes/default_spec.rb
    }
  end

  let(:expected_cookbook_files) do
    expected_cookbook_file_relpaths.map do |relpath|
      File.join(tempdir, "new_cookbook", relpath)
    end
  end

  let(:non_delivery_breadcrumb) do
    <<~EOF
      Your cookbook is ready. Type `cd new_cookbook` to enter it.

      There are several commands you can run to get started locally developing and testing your cookbook.
      Type `delivery local --help` to see a full list.

      Why not start by writing a test? Tests for the default recipe are stored at:

      test/integration/default/default_test.rb

      If you'd prefer to dive right in, the default recipe can be found at:

      recipes/default.rb
    EOF
  end

  subject(:cookbook_generator) do
    g = described_class.new(argv)
    allow(g).to receive(:cookbook_path_in_git_repo?).and_return(false)
    allow(g).to receive(:stdout).and_return(stdout_io)
    g
  end

  def generator_context
    ChefDK::Generator.context
  end

  before do
    ChefDK::Generator.reset
  end

  include_examples "custom generator cookbook" do

    let(:generator_arg) { "new_cookbook" }

    let(:generator_name) { "cookbook" }

  end

  it "configures the chef runner" do
    expect(cookbook_generator.chef_runner).to be_a(ChefDK::ChefRunner)
    expect(cookbook_generator.chef_runner.cookbook_path).to eq(File.expand_path("lib/chef-dk/skeletons", project_root))
  end

  context "when given invalid/incomplete arguments" do

    let(:expected_help_message) do
      "Usage: chef generate cookbook NAME [options]\n"
    end

    def with_argv(argv)
      generator = described_class.new(argv)
      allow(generator).to receive(:stdout).and_return(stdout_io)
      allow(generator).to receive(:stderr).and_return(stderr_io)
      generator
    end

    it "prints usage when args are empty" do
      with_argv([]).run
      expect(stderr_io.string).to include(expected_help_message)
    end

    it "errors if both berks and policyfiles are requested" do
      expect(with_argv(%w{my_cookbook --berks --policy}).run).to eq(1)
      message = "Berkshelf and Policyfiles are mutually exclusive. Please specify only one."
      expect(stderr_io.string).to include(message)
    end

    it "warns if a hyphenated cookbook name is passed" do
      expect(with_argv(%w{my-cookbook}).run).to eq(0)
      message = "Hyphens are discouraged in cookbook names as they may cause problems with custom resources. See https://docs.chef.io/ctl_chef.html#chef-generate-cookbook for more information."
      expect(stdout_io.string).to include(message)
    end

  end

  context "when given the name of the cookbook to generate" do

    let(:argv) { %w{new_cookbook} }

    before do
      reset_tempdir
    end

    it "configures the generator context" do
      cookbook_generator.read_and_validate_params
      cookbook_generator.setup_context
      expect(generator_context.cookbook_root).to eq(Dir.pwd)
      expect(generator_context.cookbook_name).to eq("new_cookbook")
      expect(generator_context.recipe_name).to eq("default")
      expect(generator_context.verbose).to be(false)
    end

    it "creates a new cookbook" do
      Dir.chdir(tempdir) do
        allow(cookbook_generator.chef_runner).to receive(:stdout).and_return(stdout_io)
        expect(cookbook_generator.run).to eq(0)
      end
      generated_files = Dir.glob("#{tempdir}/new_cookbook/**/*", File::FNM_DOTMATCH)
      expected_cookbook_files.each do |expected_file|
        expect(generated_files).to include(expected_file)
      end
    end

    context "by default configure for delivery" do

      let(:dot_delivery) { File.join(tempdir, "new_cookbook", ".delivery") }

      before do
        Dir.chdir(tempdir) do
          allow(cookbook_generator.chef_runner).to receive(:stdout).and_return(stdout_io)
          expect(cookbook_generator.run).to eq(0)
        end
      end

      describe ".delivery/project.toml" do

        let(:file) { File.join(tempdir, "new_cookbook", ".delivery", "project.toml") }

        let(:expected_content) do
          <<~PROJECT_DOT_TOML
            # Delivery Prototype for Local Phases Execution
            #
            # The purpose of this file is to prototype a new way to execute
            # phases locally on your workstation. The delivery-cli will read
            # this file and execute the command(s) that are configured for
            # each phase. You can customize them by just modifying the phase
            # key on this file.
            #
            # By default these phases are configured for Cookbook Workflow only
            #
            # As this is still a prototype we are not modifying the current
            # config.json file and it will continue working as usual.

            [local_phases]
            unit = "chef exec rspec spec/"
            lint = "chef exec cookstyle"
            # Foodcritic includes rules only appropriate for community cookbooks
            # uploaded to Supermarket. We turn off any rules tagged "supermarket"
            # by default. If you plan to share this cookbook you should remove
            # '-t ~supermarket' below to enable supermarket rules.
            syntax = "chef exec foodcritic . -t ~supermarket"
            provision = "chef exec kitchen create"
            deploy = "chef exec kitchen converge"
            smoke = "chef exec kitchen verify"
            # The functional phase is optional, you can define it by uncommenting
            # the line below and running the command: `delivery local functional`
            # functional = ""
            cleanup = "chef exec kitchen destroy"

            # Remote project.toml file
            #
            # Specify a remote URI location for the `project.toml` file.
            # This is useful for teams that wish to centrally manage the behavior
            # of the `delivery local` command across many different projects.
            #
            # remote_file = "https://url/project.toml"
          PROJECT_DOT_TOML
        end

        it "exists with default config for Cookbook Workflow" do
          expect(IO.read(file)).to eq(expected_content)
        end

      end

      describe ".delivery/config.json" do

        let(:file) { File.join(tempdir, "new_cookbook", ".delivery", "config.json") }

        let(:expected_content) do
          <<~CONFIG_DOT_JSON
            {
              "version": "2",
              "build_cookbook": {
                "name": "build_cookbook",
                "path": ".delivery/build_cookbook"
              },
              "delivery-truck": {
                "lint": {
                  "enable_cookstyle": true
                }
              },
              "skip_phases": [],
              "job_dispatch": {
                "version": "v2"
              },
              "dependencies": []
            }
          CONFIG_DOT_JSON
        end

        it "configures delivery to use a local build cookbook" do
          expect(IO.read(file)).to eq(expected_content)
        end

      end

      describe "build cookbook recipes" do

        let(:file) do
          File.join(dot_delivery, "build_cookbook", "recipes", "publish.rb")
        end

        let(:expected_content) do
          <<~CONFIG_DOT_JSON
            #
            # Cookbook:: build_cookbook
            # Recipe:: publish
            #
            # Copyright:: 2019, The Authors, All Rights Reserved.
            include_recipe 'delivery-truck::publish'
          CONFIG_DOT_JSON
        end

        it "delegates functionality to delivery-truck" do
          expect(IO.read(file)).to include(expected_content)
        end

      end

      describe "build cookbook Berksfile" do

        let(:file) do
          File.join(dot_delivery, "build_cookbook", "Berksfile")
        end

        let(:expected_content) do
          <<~CONFIG_DOT_JSON
            source 'https://supermarket.chef.io'

            metadata

            group :delivery do
              cookbook 'test', path: './test/fixtures/cookbooks/test'
            end
          CONFIG_DOT_JSON
        end

        it "sets the sources for delivery library cookbooks to github" do
          expect(IO.read(file)).to include(expected_content)
        end

      end
    end

    context "when passed delivery option" do

      let(:argv) { %w{new_cookbook --delivery} }

      it "still works with no action" do
        Dir.chdir(tempdir) do
          allow(cookbook_generator.chef_runner).to receive(:stdout).and_return(stdout_io)
          expect(cookbook_generator.run).to eq(0)
        end
      end
    end

    context "when given the verbose flag" do

      let(:argv) { %w{ new_cookbook --verbose } }

      it "configures the generator context with verbose mode enabled" do
        cookbook_generator.read_and_validate_params
        cookbook_generator.setup_context
        expect(generator_context.verbose).to be(true)
      end

      it "emits verbose output" do
        Dir.chdir(tempdir) do
          allow(cookbook_generator.chef_runner).to receive(:stdout).and_return(stdout_io)
          expect(cookbook_generator.run).to eq(0)
        end

        # The normal chef formatter puts a heading for each recipe like this.
        # Full output is large and subject to change with minor changes in the
        # generator cookbook, so we just look for this line
        expected_line = "Recipe: code_generator::cookbook"

        actual = stdout_io.string

        expect(actual).to include(expected_line)
      end
    end

    context "when no delivery CLI configuration is present" do

      it "detects no delivery config" do
        Dir.chdir(tempdir) do
          expect(cookbook_generator.have_delivery_config?).to be(false)
        end
      end

      it "emits concise output" do
        Dir.chdir(tempdir) do
          allow(cookbook_generator.chef_runner).to receive(:stdout).and_return(stdout_io)
          expect(cookbook_generator.run).to eq(0)
        end

        expected = <<~OUTPUT
          Generating cookbook new_cookbook
          - Ensuring correct cookbook file content
          - Committing cookbook files to git
          - Ensuring delivery configuration
          - Ensuring correct delivery build cookbook content
          - Adding delivery configuration to feature branch
          - Adding build cookbook to feature branch
          - Merging delivery content feature branch to master

          #{non_delivery_breadcrumb}
        OUTPUT

        actual = stdout_io.string

        # the formatter will add escape sequences to turn off any colors
        actual.gsub!("\e[0m", "")
        expect(actual).to eq(expected)
      end
    end

    context "when a delivery CLI config is present" do

      # Setup a situation like this:
      # there is a dir for the delivery organization with the
      # `.delivery/cli.toml` in it. Inside that is another dir (maybe IRL this
      # would be "cookbooks"), then we create the cookbook inside that.

      let(:tempdir_subdir) { File.join(tempdir, "subdirectory") }

      let(:dot_delivery_dir) { File.join(tempdir, ".delivery") }

      let(:dot_delivery_cli_toml) { File.join(dot_delivery_dir, "cli.toml") }

      before do
        Dir.mkdir(tempdir_subdir)
        Dir.mkdir(dot_delivery_dir)
        FileUtils.touch(dot_delivery_cli_toml)
      end

      it "detects the delivery config" do
        Dir.chdir(tempdir_subdir) do
          expect(cookbook_generator.have_delivery_config?).to be(true)
        end
      end

      it "emits concise output" do
        Dir.chdir(tempdir) do
          allow(cookbook_generator.chef_runner).to receive(:stdout).and_return(stdout_io)
          expect(cookbook_generator.run).to eq(0)
        end

        expected = <<~OUTPUT
          Generating cookbook new_cookbook
          - Ensuring correct cookbook file content
          - Committing cookbook files to git
          - Ensuring delivery configuration
          - Ensuring correct delivery build cookbook content
          - Adding delivery configuration to feature branch
          - Adding build cookbook to feature branch
          - Merging delivery content feature branch to master

          Your cookbook is ready. To setup the pipeline, type `cd new_cookbook`, then run `delivery init`
        OUTPUT

        actual = stdout_io.string

        # the formatter will add escape sequences to turn off any colors
        actual.gsub!("\e[0m", "")
        expect(actual).to eq(expected)
      end
    end

    shared_examples_for "a generated file" do |context_var|
      before do
        Dir.chdir(tempdir) do
          allow(cookbook_generator.chef_runner).to receive(:stdout).and_return(stdout_io)
          expect(cookbook_generator.run).to eq(0)
        end
      end

      it "should contain #{context_var} from the generator context" do
        expect(File.read(file)).to match line
      end
    end

    describe "README.md" do
      let(:file) { File.join(tempdir, "new_cookbook", "README.md") }

      include_examples "a generated file", :cookbook_name do
        let(:line) { "# new_cookbook" }
      end
    end

    describe "CHANGELOG.md" do
      let(:file) { File.join(tempdir, "new_cookbook", "CHANGELOG.md") }

      include_examples "a generated file", :cookbook_name do
        let(:line) { "# new_cookbook" }
      end
    end

    # This shared example group requires a let binding for
    # `expected_kitchen_yml_content`
    shared_examples_for "kitchen_yml_and_integration_tests" do

      describe "Generating Test Kitchen and integration testing files" do

        describe "generating kitchen config" do

          before do
            Dir.chdir(tempdir) do
              allow(cookbook_generator.chef_runner).to receive(:stdout).and_return(stdout_io)
              expect(cookbook_generator.run).to eq(0)
            end
          end

          let(:file) { File.join(tempdir, "new_cookbook", ".kitchen.yml") }

          it "creates a .kitchen.yml with the expected content" do
            expect(IO.read(file)).to eq(expected_kitchen_yml_content)
          end

        end

        describe "test/integration/default/default_test.rb" do
          let(:file) { File.join(tempdir, "new_cookbook", "test", "integration", "default", "default_test.rb") }

          include_examples "a generated file", :cookbook_name do
            let(:line) { "describe port" }
          end
        end
      end
    end

    # This shared example group requires you to define a let binding for
    # `expected_chefspec_spec_helper_content`
    shared_examples_for "chefspec_spec_helper_file" do

      describe "Generating ChefSpec files" do

        before do
          Dir.chdir(tempdir) do
            allow(cookbook_generator.chef_runner).to receive(:stdout).and_return(stdout_io)
            expect(cookbook_generator.run).to eq(0)
          end
        end

        let(:file) { File.join(tempdir, "new_cookbook", "spec", "spec_helper.rb") }

        it "creates a spec/spec_helper.rb for ChefSpec with the expected content" do
          expect(IO.read(file)).to eq(expected_chefspec_spec_helper_content)
        end

      end

    end

    context "when configured for Policyfiles" do

      let(:argv) { %w{new_cookbook --policy} }

      describe "Policyfile.rb" do

        let(:file) { File.join(tempdir, "new_cookbook", "Policyfile.rb") }

        let(:expected_content) do
          <<~POLICYFILE_RB
            # Policyfile.rb - Describe how you want Chef to build your system.
            #
            # For more information on the Policyfile feature, visit
            # https://docs.chef.io/policyfile.html

            # A name that describes what the system you're building with Chef does.
            name 'new_cookbook'

            # Where to find external cookbooks:
            default_source :supermarket

            # run_list: chef-client will run these recipes in the order specified.
            run_list 'new_cookbook::default'

            # Specify a custom source for a single cookbook:
            cookbook 'new_cookbook', path: '.'
          POLICYFILE_RB
        end

        before do
          Dir.chdir(tempdir) do
            allow(cookbook_generator.chef_runner).to receive(:stdout).and_return(stdout_io)
            expect(cookbook_generator.run).to eq(0)
          end
        end

        it "has a run_list and cookbook path that will work out of the box" do
          expect(IO.read(file)).to eq(expected_content)
        end

      end

      include_examples "kitchen_yml_and_integration_tests" do

        let(:expected_kitchen_yml_content) do
          <<~KITCHEN_YML
            ---
            driver:
              name: vagrant

            ## The forwarded_port port feature lets you connect to ports on the VM guest via
            ## localhost on the host.
            ## see also: https://docs.vagrantup.com/v2/networking/forwarded_ports.html

            #  network:
            #    - ["forwarded_port", {guest: 80, host: 8080}]

            provisioner:
              name: chef_zero

            ## require_chef_omnibus specifies a specific chef version to install. You can
            ## also set this to `true` to always use the latest version.
            ## see also: https://docs.chef.io/config_yml_kitchen.html

            #  require_chef_omnibus: 12.8.1

            verifier:
              name: inspec

            platforms:
              - name: ubuntu-16.04
              - name: centos-7

            suites:
              - name: default
                verifier:
                  inspec_tests:
                    - test/integration/default
                attributes:
          KITCHEN_YML
        end

      end

      include_examples "chefspec_spec_helper_file" do

        let(:expected_chefspec_spec_helper_content) do
          <<~SPEC_HELPER
            # frozen_string_literal: true
            require 'chefspec'
            require 'chefspec/policyfile'
          SPEC_HELPER
        end

      end

    end

    context "when configured for Berkshelf" do

      let(:argv) { %w{new_cookbook --berks} }

      describe "Berksfile" do

        let(:file) { File.join(tempdir, "new_cookbook", "Berksfile") }

        let(:expected_content) do
          <<~POLICYFILE_RB
            # frozen_string_literal: true
            source 'https://supermarket.chef.io'

            metadata
          POLICYFILE_RB
        end

        before do
          Dir.chdir(tempdir) do
            allow(cookbook_generator.chef_runner).to receive(:stdout).and_return(stdout_io)
            expect(cookbook_generator.run).to eq(0)
          end
        end

        it "pulls deps from metadata" do
          expect(IO.read(file)).to eq(expected_content)
        end

      end

      include_examples "kitchen_yml_and_integration_tests" do

        let(:expected_kitchen_yml_content) do
          <<~KITCHEN_YML
            ---
            driver:
              name: vagrant

            provisioner:
              name: chef_zero
              # You may wish to disable always updating cookbooks in CI or other testing environments.
              # For example:
              #   always_update_cookbooks: <%= !ENV['CI'] %>
              always_update_cookbooks: true

            verifier:
              name: inspec

            platforms:
              - name: ubuntu-16.04
              - name: centos-7

            suites:
              - name: default
                run_list:
                  - recipe[new_cookbook::default]
                verifier:
                  inspec_tests:
                    - test/integration/default
                attributes:
          KITCHEN_YML
        end

      end

      include_examples "chefspec_spec_helper_file" do

        let(:expected_chefspec_spec_helper_content) do
          <<~SPEC_HELPER
            # frozen_string_literal: true
            require 'chefspec'
            require 'chefspec/berkshelf'
          SPEC_HELPER
        end

      end

    end

    describe "metadata.rb" do
      let(:file) { File.join(tempdir, "new_cookbook", "metadata.rb") }

      include_examples "a generated file", :cookbook_name do
        let(:line) { /name\s+'new_cookbook'.+# issues_url.+# source_url/m }
      end
    end

    describe "recipes/default.rb" do
      let(:file) { File.join(tempdir, "new_cookbook", "recipes", "default.rb") }

      include_examples "a generated file", :cookbook_name do
        let(:line) { "# Cookbook:: new_cookbook" }
      end
    end

    describe "spec/unit/recipes/default_spec.rb" do
      let(:file) { File.join(tempdir, "new_cookbook", "spec", "unit", "recipes", "default_spec.rb") }

      include_examples "a generated file", :cookbook_name do
        let(:line) { "describe 'new_cookbook::default' do" }
      end
    end

  end

  context "when given the path to the cookbook to generate" do
    let(:argv) { [ File.join(tempdir, "a_new_cookbook") ] }

    before do
      reset_tempdir
    end

    it "configures the generator context" do
      cookbook_generator.read_and_validate_params
      cookbook_generator.setup_context
      expect(generator_context.cookbook_root).to eq(tempdir)
      expect(generator_context.cookbook_name).to eq("a_new_cookbook")
    end

  end

  context "when given generic arguments to populate the generator context" do
    let(:argv) { [ "new_cookbook", "--generator-arg", "key1=value1", "-a", "key2=value2", "-a", " key3 = value3 " ] }

    before do
      reset_tempdir
    end

    it "configures the generator context for long form option key1" do
      cookbook_generator.read_and_validate_params
      cookbook_generator.setup_context
      expect(generator_context.key1).to eq("value1")
    end

    it "configures the generator context for short form option key2" do
      cookbook_generator.read_and_validate_params
      cookbook_generator.setup_context
      expect(generator_context.key2).to eq("value2")
    end

    it "configures the generator context for key3 containing additional spaces" do
      cookbook_generator.read_and_validate_params
      cookbook_generator.setup_context
      expect(generator_context.key3).to eq("value3")
    end

  end

end
