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
require "shared/custom_generator_cookbook"
require "shared/setup_git_committer_config"
require "chef-dk/command/generator_commands/build_cookbook"
require "mixlib/shellout"

describe ChefDK::Command::GeneratorCommands::BuildCookbook do

  include_context("setup_git_committer_config")

  let(:argv) { %w{delivery_project} }

  let(:stdout_io) { StringIO.new }
  let(:stderr_io) { StringIO.new }

  let(:expected_cookbook_file_relpaths) do
    %w{
      .kitchen.yml
      data_bags
      data_bags/keys
      data_bags/keys/delivery_builder_keys.json
      test
      test/fixtures
      test/fixtures/cookbooks
      test/fixtures/cookbooks/test
      test/fixtures/cookbooks/test/metadata.rb
      test/fixtures/cookbooks/test/recipes
      test/fixtures/cookbooks/test/recipes/default.rb
      Berksfile
      chefignore
      metadata.rb
      README.md
      LICENSE
      recipes
      recipes/default.rb
      recipes/deploy.rb
      recipes/functional.rb
      recipes/lint.rb
      recipes/provision.rb
      recipes/publish.rb
      recipes/quality.rb
      recipes/security.rb
      recipes/smoke.rb
      recipes/syntax.rb
      recipes/unit.rb
      secrets
      secrets/fakey-mcfakerton
    }
  end

  let(:expected_cookbook_files) do
    expected_cookbook_file_relpaths.map do |relpath|
      File.join(tempdir, "delivery_project", ".delivery", "build_cookbook", relpath)
    end
  end

  subject(:cookbook_generator) do
    described_class.new(argv)
  end

  def generator_context
    ChefDK::Generator.context
  end

  before do
    ChefDK::Generator.reset
  end

  it "configures the chef runner" do
    expect(cookbook_generator.chef_runner).to be_a(ChefDK::ChefRunner)
    expect(cookbook_generator.chef_runner.cookbook_path).to eq(File.expand_path("lib/chef-dk/skeletons", project_root))
  end

  context "when given invalid/incomplete arguments" do

    let(:expected_help_message) do
      "Usage: chef generate build-cookbook NAME [options]\n"
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

  end

  context "when given the name of the delivery project" do

    let(:argv) { %w{delivery_project} }

    let(:project_dir) { File.join(tempdir, "delivery_project") }

    before do
      reset_tempdir
      Dir.mkdir(project_dir)
    end

    it "configures the generator context" do
      cookbook_generator.read_and_validate_params
      cookbook_generator.setup_context
      expect(generator_context.delivery_project_dir).to eq(File.join(Dir.pwd, "delivery_project"))
    end

    it "creates a build cookbook" do
      Dir.chdir(tempdir) do
        allow(cookbook_generator.chef_runner).to receive(:stdout).and_return(stdout_io)
        expect(cookbook_generator.run).to eq(0)
      end
      generated_files = Dir.glob("#{tempdir}/delivery_project/**/*", File::FNM_DOTMATCH)
      expected_cookbook_files.each do |expected_file|
        expect(generated_files).to include(expected_file)
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
        expect(File.read(file)).to include(line)
      end
    end

    # This shared example group requires a let binding for
    # `expected_kitchen_yml_content`
    shared_examples_for "kitchen_yml_and_integration_tests" do

      describe "Generating Test Kitchen and integration testing files" do

        before do
          Dir.chdir(tempdir) do
            allow(cookbook_generator.chef_runner).to receive(:stdout).and_return(stdout_io)
            expect(cookbook_generator.run).to eq(0)
          end
        end

        let(:file) { File.join(tempdir, "delivery_project", ".delivery", "build_cookbook", ".kitchen.yml") }

        it "creates a .kitchen.yml with the expected content" do
          expect(IO.read(file)).to eq(expected_kitchen_yml_content)
        end

      end
    end

    context "when the delivery project is a cookbook" do

      let(:parent_metadata_rb) { File.join(tempdir, "delivery_project", "metadata.rb") }

      before do
        FileUtils.touch(parent_metadata_rb)
      end

      it "detects that the parent project is a cookbook" do
        Dir.chdir(tempdir) do
          cookbook_generator.read_and_validate_params
          cookbook_generator.setup_context
          expect(generator_context.build_cookbook_parent_is_cookbook).to eq(true)
        end
      end

      describe "metadata.rb" do
        let(:file) { File.join(tempdir, "delivery_project", ".delivery", "build_cookbook", "metadata.rb") }

        include_examples "a generated file", :cookbook_name do
          let(:line) do
            <<~METADATA
              name 'build_cookbook'
              maintainer 'The Authors'
              maintainer_email 'you@example.com'
              license 'all_rights'
              version '0.1.0'
              chef_version '>= 13.0'

              depends 'delivery-truck'
            METADATA
          end
        end
      end

      describe "delivery phase recipes" do

        before do
          Dir.chdir(tempdir) do
            allow(cookbook_generator.chef_runner).to receive(:stdout).and_return(stdout_io)
            expect(cookbook_generator.run).to eq(0)
          end
        end

        it "generates phase recipes which include the corresponding delivery truck recipe" do
          %w{
            deploy.rb
            functional.rb
            lint.rb
            provision.rb
            publish.rb
            quality.rb
            security.rb
            smoke.rb
            syntax.rb
            unit.rb
          }.each do |phase_recipe|
            recipe_file = File.join(tempdir, "delivery_project", ".delivery", "build_cookbook", "recipes", phase_recipe)
            phase = File.basename(phase_recipe, ".rb")
            expected_content = %Q{include_recipe 'delivery-truck::#{phase}'}
            expect(IO.read(recipe_file)).to include(expected_content)
          end
        end

      end

    end

    context "when the delivery project is not a cookbook" do

      it "detects that the parent project is not a cookbook" do
        cookbook_generator.read_and_validate_params
        cookbook_generator.setup_context
        expect(generator_context.build_cookbook_parent_is_cookbook).to eq(false)
      end

      describe "metadata.rb" do
        let(:file) { File.join(tempdir, "delivery_project", ".delivery", "build_cookbook", "metadata.rb") }

        include_examples "a generated file", :cookbook_name do
          let(:line) do
            <<~METADATA
              name 'build_cookbook'
              maintainer 'The Authors'
              maintainer_email 'you@example.com'
              license 'all_rights'
              version '0.1.0'
            METADATA
          end
        end
      end

      describe "delivery phase recipes" do

        before do
          Dir.chdir(tempdir) do
            allow(cookbook_generator.chef_runner).to receive(:stdout).and_return(stdout_io)
            expect(cookbook_generator.run).to eq(0)
          end
        end

        it "generates phase recipes that are empty" do
          %w{
            deploy.rb
            functional.rb
            lint.rb
            provision.rb
            publish.rb
            quality.rb
            security.rb
            smoke.rb
            syntax.rb
            unit.rb
          }.each do |phase_recipe|
            recipe_file = File.join(tempdir, "delivery_project", ".delivery", "build_cookbook", "recipes", phase_recipe)
            expect(IO.read(recipe_file)).to_not include("include_recipe")
          end
        end

      end

    end

    context "when the delivery project is a git repo" do

      let(:readme) { File.join(project_dir, "README.md") }

      def git!(cmd)
        Mixlib::ShellOut.new("git #{cmd}", cwd: project_dir).tap do |c|
          c.run_command
          c.error!
        end
      end

      before do
        FileUtils.touch(readme)

        git!("init .")
        git!("add .")
        git!("commit --no-gpg-sign -m \"initial commit\"")

        Dir.chdir(tempdir) do
          allow(cookbook_generator.chef_runner).to receive(:stdout).and_return(stdout_io)
          expect(cookbook_generator.run).to eq(0)
        end
      end

      it "creates delivery config in a feature branch and merges it" do
        expect(git!("log").stdout).to include("Merge branch 'add-delivery-configuration'")
      end

    end

    context "when the delivery project has already a config.json and project.toml" do

      let(:dot_delivery) { File.join(project_dir, ".delivery") }
      let(:config_json) { File.join(dot_delivery, "config.json") }
      let(:project_toml) { File.join(dot_delivery, "project.toml") }

      def git!(cmd)
        Mixlib::ShellOut.new("git #{cmd}", cwd: project_dir).tap do |c|
          c.run_command
          c.error!
        end
      end

      before do
        FileUtils.mkdir_p(dot_delivery)
        FileUtils.touch(config_json)
        FileUtils.touch(project_toml)

        git!("init .")
        git!("add .")
        git!("commit --no-gpg-sign -m \"initial commit\"")

        Dir.chdir(tempdir) do
          allow(cookbook_generator.chef_runner).to receive(:stdout).and_return(stdout_io)
          expect(cookbook_generator.run).to eq(0)
        end
      end

      it "does not overwrite the delivery config" do
        expect(git!("log").stdout).to_not include("Add generated delivery configuration")
      end

    end
  end

  context "when given a path including the .delivery directory" do
    let(:argv) { [ File.join(tempdir, "delivery_project", ".delivery", "build_cookbook") ] }

    before do
      reset_tempdir
    end

    it "correctly sets the delivery project dir to the parent of the .delivery dir" do
      cookbook_generator.read_and_validate_params
      cookbook_generator.setup_context
      expect(generator_context.delivery_project_dir).to eq(File.join(tempdir, "delivery_project"))
    end

  end

end
