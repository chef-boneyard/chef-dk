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
require 'chef-dk/command/generator_commands'

describe ChefDK::Command::GeneratorCommands::App do

  let(:argv) { %w[new_app] }

  let(:stdout_io) { StringIO.new }
  let(:stderr_io) { StringIO.new }

  let(:expected_cookbook_file_relpaths) do
    %w[
      .gitignore
      .kitchen.yml
      README.md
      cookbooks/new_app/Berksfile
      cookbooks/new_app/chefignore
      cookbooks/new_app/metadata.rb
      cookbooks/new_app/recipes
      cookbooks/new_app/recipes/default.rb
    ]
  end

  let(:expected_cookbook_files) do
    expected_cookbook_file_relpaths.map do |relpath|
      File.join(tempdir, "new_app", relpath)
    end
  end

  subject(:cookbook_generator) { described_class.new(argv) }

  def generator_context
    ChefDK::Generator.context
  end

  before do
    ChefDK::Generator.reset
  end

  context "when given the name of the cookbook to generate" do

    before do
      reset_tempdir
    end

    it "configures the generator context" do
      cookbook_generator.read_and_validate_params
      cookbook_generator.setup_context
      expect(generator_context.app_root).to eq(Dir.pwd)
      expect(generator_context.app_name).to eq("new_app")
    end

    it "creates a new cookbook" do
      Dir.chdir(tempdir) do
        cookbook_generator.chef_runner.stub(:stdout).and_return(stdout_io)
        cookbook_generator.run
      end
      generated_files = Dir.glob("#{tempdir}/new_app/**/*", File::FNM_DOTMATCH)
      expected_cookbook_files.each do |expected_file|
        expect(generated_files).to include(expected_file)
      end
    end

  end

end

describe ChefDK::Command::GeneratorCommands::Cookbook do

  let(:argv) { %w[new_cookbook] }

  let(:stdout_io) { StringIO.new }
  let(:stderr_io) { StringIO.new }

  let(:expected_cookbook_file_relpaths) do
    %w[
      .gitignore
      .kitchen.yml
      Berksfile
      chefignore
      metadata.rb
      README.md
      recipes
      recipes/default.rb
    ]
  end

  let(:expected_cookbook_files) do
    expected_cookbook_file_relpaths.map do |relpath|
      File.join(tempdir, "new_cookbook", relpath)
    end
  end

  subject(:cookbook_generator) do
    g = described_class.new(argv)
    g.stub(:cookbook_path_in_git_repo?).and_return(false)
    g
  end

  def generator_context
    ChefDK::Generator.context
  end

  before do
    ChefDK::Generator.reset
  end

  it "configures the chef runner" do
    expect(cookbook_generator.chef_runner).to be_a(ChefDK::ChefRunner)
    expect(cookbook_generator.chef_runner.cookbook_path).to eq(File.expand_path('lib/chef-dk/skeletons', project_root))
  end

  context "when given invalid/incomplete arguments" do

    let(:expected_help_message) do
      "Usage: chef generate cookbook NAME [options]\n"
    end


    def with_argv(argv)
      generator = described_class.new(argv)
      generator.stub(:stdout).and_return(stdout_io)
      generator.stub(:stderr).and_return(stderr_io)
      generator
    end

    it "prints usage when args are empty" do
      with_argv([]).run
      expect(stdout_io.string).to eq(expected_help_message)
    end

  end

  context "when given the name of the cookbook to generate" do

    let(:argv) { %w[new_cookbook] }

    before do
      reset_tempdir
    end

    it "configures the generator context" do
      cookbook_generator.read_and_validate_params
      cookbook_generator.setup_context
      expect(generator_context.cookbook_root).to eq(Dir.pwd)
      expect(generator_context.cookbook_name).to eq("new_cookbook")
    end

    it "creates a new cookbook" do
      Dir.chdir(tempdir) do
        cookbook_generator.chef_runner.stub(:stdout).and_return(stdout_io)
        cookbook_generator.run
      end
      generated_files = Dir.glob("#{tempdir}/new_cookbook/**/*", File::FNM_DOTMATCH)
      expected_cookbook_files.each do |expected_file|
        expect(generated_files).to include(expected_file)
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

  context "when given a generator-cookbook path" do
    let(:generator_cookbook_path) { File.join(tempdir, 'a_generator_cookbook') }
    let(:argv) { ["new_cookbook", "--generator-cookbook", generator_cookbook_path] }

    before do
      reset_tempdir
    end

    it "configures the generator context" do
      cookbook_generator.read_and_validate_params
      cookbook_generator.setup_context
      expect(generator_context.cookbook_root).to eq(Dir.pwd)
      expect(generator_context.cookbook_name).to eq("new_cookbook")
      expect(cookbook_generator.chef_runner.cookbook_path).to eq(generator_cookbook_path)
    end

    it "creates a new cookbook" do
      Dir.chdir(tempdir) do
        cookbook_generator.chef_runner.stub(:stdout).and_return(stdout_io)
        cookbook_generator.run
      end
      generated_files = Dir.glob("#{tempdir}/new_cookbook/**/*", File::FNM_DOTMATCH)
      expected_cookbook_files.each do |expected_file|
        expect(generated_files).to include(expected_file)
      end
    end
  end

end

shared_examples_for "a file generator" do

  let(:stdout_io) { StringIO.new }
  let(:stderr_io) { StringIO.new }

  def stdout
    stdout_io.string
  end

  def stderr
    stderr_io.string
  end

  let(:expected_cookbook_root) { tempdir }
  let(:cookbook_name) { "example_cookbook" }

  let(:cookbook_path) { File.join(tempdir, cookbook_name) }

  subject(:recipe_generator) do
    generator = described_class.new(argv)
    generator.stub(:stdout).and_return(stdout_io)
    generator.stub(:stderr).and_return(stderr_io)
    generator
  end

  def generator_context
    ChefDK::Generator.context
  end

  before do
    ChefDK::Generator.reset
    reset_tempdir
  end

  context "when argv is empty" do
    let(:argv) { [] }

    it "emits an error message and exits" do
      expected_stdout = "Usage: chef generate #{generator_name} [path/to/cookbook] NAME [options]"

      expect(recipe_generator.run).to eq(1)
      expect(stdout).to include(expected_stdout)
    end
  end

  context "when CWD is a cookbook" do

    let(:argv) { [ new_file_name ] }

    before do
      FileUtils.cp_r(File.join(fixtures_path, "example_cookbook"), tempdir)
    end

    it "configures the generator context" do
      Dir.chdir(cookbook_path) do
        recipe_generator.read_and_validate_params
        recipe_generator.setup_context

        expect(generator_context.cookbook_root).to eq(expected_cookbook_root)
        expect(generator_context.cookbook_name).to eq(cookbook_name)
        expect(generator_context.new_file_basename).to eq(new_file_name)
      end
    end

    it "creates a new recipe" do
      Dir.chdir(cookbook_path) do
        recipe_generator.chef_runner.stub(:stdout).and_return(stdout_io)
        recipe_generator.run
      end

        generated_files.each do |expected_file|
          expect(File).to exist(File.join(cookbook_path, expected_file))
        end
    end

  end

  context "when CWD is not a cookbook" do
    context "and path to the cookbook is not given in the agv" do
      let(:argv) { [ new_file_name ] }

      it "emits an error message and exits" do
        expected_stdout = "Usage: chef generate #{generator_name} [path/to/cookbook] NAME [options]"
        expected_stderr = "Error: Directory #{Dir.pwd} is not a cookbook\n"

        expect(recipe_generator.run).to eq(1)
        expect(stdout).to include(expected_stdout)
        expect(stderr).to eq(expected_stderr)
      end
    end

    context "and path to the cookbook is given in the argv" do
      let(:argv) { [cookbook_path, new_file_name ] }

      before do
        FileUtils.cp_r(File.join(fixtures_path, "example_cookbook"), tempdir)
      end

      it "configures the generator context" do
        recipe_generator.read_and_validate_params
        recipe_generator.setup_context

        expect(generator_context.cookbook_root).to eq(File.dirname(cookbook_path))
        expect(generator_context.cookbook_name).to eq(cookbook_name)
        expect(generator_context.new_file_basename).to eq(new_file_name)
      end

      it "creates a new recipe" do
        recipe_generator.chef_runner.stub(:stdout).and_return(stdout_io)
        recipe_generator.run

        generated_files.each do |expected_file|
          expect(File).to exist(File.join(cookbook_path, expected_file))
        end
      end

    end
  end

end

describe ChefDK::Command::GeneratorCommands::Recipe do

  include_examples "a file generator" do

    let(:generator_name) { "recipe" }
    let(:generated_files) { [ "recipes/new_recipe.rb" ] }
    let(:new_file_name) { "new_recipe" }

  end
end

describe ChefDK::Command::GeneratorCommands::Attribute do

  include_examples "a file generator" do

    let(:generator_name) { "attribute" }
    let(:generated_files) { [ "attributes/new_attribute_file.rb" ] }
    let(:new_file_name) { "new_attribute_file" }

  end
end

describe ChefDK::Command::GeneratorCommands::LWRP do

  include_examples "a file generator" do

    let(:generator_name) { "lwrp" }
    let(:generated_files) { [ "resources/new_lwrp.rb", "providers/new_lwrp.rb" ] }
    let(:new_file_name) { "new_lwrp" }

  end
end

describe ChefDK::Command::GeneratorCommands::Template do

  include_examples "a file generator" do

    let(:generator_name) { "template" }
    let(:generated_files) { [ "templates/default/new_template.txt.erb" ] }
    let(:new_file_name) { "new_template.txt" }

  end
end

describe ChefDK::Command::GeneratorCommands::Template do

  include_examples "a file generator" do

    let(:generator_name) { "template" }
    let(:generated_files) { [ "templates/default/new_template.erb" ] }
    let(:new_file_name) { "new_template.erb" }

  end
end

describe ChefDK::Command::GeneratorCommands::CookbookFile do

  include_examples "a file generator" do

    let(:generator_name) { "file" }
    let(:generated_files) { [ "files/default/new_file.txt" ] }
    let(:new_file_name) { "new_file.txt" }

  end
end
